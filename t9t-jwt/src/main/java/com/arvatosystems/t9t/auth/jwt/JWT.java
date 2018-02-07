package com.arvatosystems.t9t.auth.jwt;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.Key;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.UnrecoverableKeyException;
import java.security.cert.X509Certificate;
import java.util.Arrays;
import java.util.Base64;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

import javax.crypto.Mac;

import org.joda.time.Instant;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import de.jpaw.bonaparte.api.auth.JwtConverter;
import de.jpaw.bonaparte.core.BonaparteJsonEscaper;
import de.jpaw.bonaparte.core.MimeTypes;
import de.jpaw.bonaparte.pojos.api.auth.JwtAlg;
import de.jpaw.bonaparte.pojos.api.auth.JwtInfo;
import de.jpaw.util.ExceptionUtil;

/**
 * JWT and JWS implementation draft-ietf-oauth-json-web-token-32.
 *
 * @author Paulo Lopes
 * Modified to fit into bonaparte environment by Arvato Systems
 */
public final class JWT implements IJWT {
    private static final Logger LOGGER = LoggerFactory.getLogger(JWT.class);
    private static final Charset UTF8 = StandardCharsets.UTF_8;
    private static final AtomicBoolean INSTANCES_CREATED = new AtomicBoolean();

    private final Map<String, Crypto> CRYPTO_MAP;
    private static String DEFAULT_KEYSTORE = "/t9tkeystore.jceks";
    private static String DEFAULT_KEYSTORE_PW = "Z2Ug8#+lKr/Ww";
    private static boolean KEYSTORE_FROM_RESOURCE = true;         // load the keystore from resource instead of file system

    static public void setKeyStore(String path, String password, boolean isResource) {
        if (INSTANCES_CREATED.get()) {
            throw new RuntimeException("Cannot modify static parameters after default JWTs have been created");
        }
        if (password != null) {
            DEFAULT_KEYSTORE_PW = password;
        }
        if (path != null) {
            DEFAULT_KEYSTORE = path;
            KEYSTORE_FROM_RESOURCE = isResource;
        }
    }

    static public JWT createDefaultJwt() {
        INSTANCES_CREATED.set(true);
        try {
            return createJwt(KEYSTORE_FROM_RESOURCE
                    ? IJWT.class.getResourceAsStream(DEFAULT_KEYSTORE)
                    : new FileInputStream(DEFAULT_KEYSTORE),
                    DEFAULT_KEYSTORE_PW);
        } catch (FileNotFoundException e) {
            throw new RuntimeException("No keystore file " + DEFAULT_KEYSTORE + " found");
        }
    }

    static public JWT createJwt(InputStream in, String password) {
        if (in == null) {
            LOGGER.info("No keystore inputstream provided - keystore file may be missing from the deployment");
            throw new RuntimeException("No inputstream for keyfile provided");
        }
        LOGGER.debug("Creating new JWT authentication instance");
        try {
            KeyStore ks = KeyStore.getInstance("jceks");
            ks.load(in, password.toCharArray());
            in.close();

            return new JWT(ks, password.toCharArray());
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public JWT(final KeyStore keyStore, final char[] keyStorePassword) {

        final Map<String, Crypto> tmp = new HashMap<>();

        // load MACs
        for (String alg : Arrays.<String> asList("HS256", "HS384", "HS512")) {
            try {
                Mac mac = getMac(keyStore, keyStorePassword, alg);
                if (mac != null) {
                    tmp.put(alg, new CryptoMac(mac));
                } else {
                    LOGGER.warn("{} not available", alg);
                }
            } catch (RuntimeException e) {
                LOGGER.warn(alg + " not supported", e);
            }
        }

        // load SIGNATUREs
        for (String alg : Arrays.<String> asList("RS256", "RS384", "RS512", "ES256", "ES384", "ES512")) {
            try {
                X509Certificate certificate = getCertificate(keyStore, alg);
                PrivateKey privateKey = getPrivateKey(keyStore, keyStorePassword, alg);
                if (certificate != null && privateKey != null) {
                    tmp.put(alg, new CryptoSignature(certificate, privateKey));
                } else {
                    LOGGER.warn("JWT algorithm {} not available", alg);
                }
            } catch (Exception e) {
                LOGGER.warn("{} not supported: {}", alg, ExceptionUtil.causeChain(e));
            }
        }

        // Spec requires "none" to always be available, but according to https://www.owasp.org/index.php/JSON_Web_Token_(JWT)_Cheat_Sheet_for_Java
        // that would be a very bad idea! Therefore we do not do that.

        CRYPTO_MAP = Collections.unmodifiableMap(tmp);
    }

    /**
     * Creates a new Message Authentication Code
     *
     * @param keyStore a valid JKS
     * @param alias algorithm to use e.g.: HmacSHA256
     * @return Mac implementation
     */
    private Mac getMac(final KeyStore keyStore, final char[] keyStorePassword, final String alias) {
        try {
            final Key secretKey = keyStore.getKey(alias, keyStorePassword);

            // key store does not have the requested algorithm
            if (secretKey == null) {
                return null;
            }

            Mac mac = Mac.getInstance(secretKey.getAlgorithm());
            mac.init(secretKey);

            return mac;
        } catch (NoSuchAlgorithmException | InvalidKeyException | UnrecoverableKeyException | KeyStoreException e) {
            throw new RuntimeException(e);
        }
    }

    private X509Certificate getCertificate(final KeyStore keyStore, final String alias) {
        try {
            return (X509Certificate) keyStore.getCertificate(alias);
        } catch (KeyStoreException e) {
            throw new RuntimeException(e);
        }
    }

    private PrivateKey getPrivateKey(final KeyStore keyStore, final char[] keyStorePassword, final String alias) {
        try {
            return (PrivateKey) keyStore.getKey(alias, keyStorePassword);

        } catch (NoSuchAlgorithmException | UnrecoverableKeyException | KeyStoreException e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public JwtInfo decode(final String token) {
        String[] segments = token.split("\\.");
        if (segments.length != 3)
            throw new T9tJwtException(T9tJwtException.NUMBER_SEGMENTS, Integer.toString(segments.length));

        // All segment should be base64
        String headerSeg = segments[0];
        String payloadSeg = segments[1];
        String signatureSeg = segments[2];

        if (signatureSeg.length() == 0)
            throw new T9tJwtException(T9tJwtException.MISSING_SIGNATURE);

        // base64 decode and parse JSON
        JwtAlg header;
        JwtInfo payload;
        try {
            header = JwtConverter.parseAlg(new String(base64urlDecode(headerSeg), UTF8));
            payload = JwtConverter.parseJwtInfo(new String(base64urlDecode(payloadSeg), UTF8));
        } catch (IllegalArgumentException e) { // Decoding illegal information will throw an IllegalArgumentException which should be caught!
            throw new T9tJwtException(T9tJwtException.VERIFICATION_FAILED);
        }

        Crypto crypto = CRYPTO_MAP.get(header.getAlg());

        if (crypto == null)
            throw new T9tJwtException(T9tJwtException.ALGORITHM_NOT_SUPPORTED, header.getAlg());

        // verify signature. `sign` will return base64 string.
        String signingInput = headerSeg + "." + payloadSeg;

        try {
            if (!crypto.verify(base64urlDecode(signatureSeg), signingInput.getBytes(UTF8)))
                throw new T9tJwtException(T9tJwtException.VERIFICATION_FAILED);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        return payload;

    }

    @Override
    public String sign(JwtInfo info, Long expiresInSeconds, String algorithmOverride) {
        final String algorithm = algorithmOverride == null ? "HS256" : algorithmOverride;

        Crypto crypto = CRYPTO_MAP.get(algorithm);

        if (crypto == null)
            throw new T9tJwtException(T9tJwtException.ALGORITHM_NOT_SUPPORTED, algorithm);

        // header, typ is fixed value.
        String header = "{\"typ\":\"JWT\",\"alg\":\"" + algorithm + "\"}";

        // set the "issued at" field
        long timestamp = System.currentTimeMillis() / 1000L;  // divide it to get 1 second precision
        info.setIssuedAt(new Instant(timestamp * 1000L));

        // if a duration has been given, set the expiry time
        if (expiresInSeconds != null)
            info.setExpiresAt(new Instant((timestamp + expiresInSeconds.longValue()) * 1000L));

        Map<String, Object> payload = JwtConverter.asMap(info);
        payload.put(MimeTypes.JSON_FIELD_PQON, "api.auth.JwtPayload");

        String json = BonaparteJsonEscaper.asJson(payload);

        try {
            // create segments, all segment should be base64 string
            String headerSegment = base64urlEncode(header);
            String payloadSegment = base64urlEncode(json);
            String signingInput = headerSegment + "." + payloadSegment;
            String signSegment = base64urlEncode(crypto.sign(signingInput.getBytes(UTF8)));
            return headerSegment + "." + payloadSegment + "." + signSegment;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private static byte[] base64urlDecode(String str) {
        return Base64.getUrlDecoder().decode(str.getBytes(UTF8));
    }

    private static String base64urlEncode(String str) {
        return base64urlEncode(str.getBytes(UTF8));
    }

    private static String base64urlEncode(byte[] bytes) {
        return Base64.getUrlEncoder().encodeToString(bytes);
    }
}
