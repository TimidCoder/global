package com.arvatosystems.t9t.auth.be.impl

import com.arvatosystems.t9t.auth.SessionDTO
import com.arvatosystems.t9t.auth.TenantRef
import com.arvatosystems.t9t.auth.UserRef
import com.arvatosystems.t9t.auth.services.IAuthPersistenceAccess
import com.arvatosystems.t9t.auth.services.IAuthenticator
import com.arvatosystems.t9t.base.services.IRefGenerator
import com.arvatosystems.t9t.base.types.SessionParameters
import de.jpaw.annotations.AddLogger
import de.jpaw.bonaparte.pojos.api.auth.JwtInfo
import de.jpaw.bonaparte.util.ToStringHelper
import de.jpaw.dp.Inject
import de.jpaw.dp.Singleton
import java.util.UUID

@AddLogger
@Singleton
class AuthResponseUtil {
    public final String ISSUER_APIKEY          = "AK";
    public final String ISSUER_USERID_PASSWORD = "UP";

    @Inject IAuthenticator          authenticator
    @Inject IAuthPersistenceAccess  persistenceAccess
    @Inject IRefGenerator           refGenerator

    def String normalize(String in) {
        if (in === null)
            return null
        val trimmed = in.trim
        if (trimmed.length == 0)
            return null
        return trimmed
    }

    // common part of code for SwitchTenantRequest and AuthenticationRequest
    def String authResponseFromJwt(JwtInfo jwt, SessionParameters sp, JwtInfo continuesFromJwt) {
        jwt.sessionId           = UUID.randomUUID
        jwt.sessionRef          = refGenerator.generateRef(SessionDTO.class$rtti)
        jwt.resource            = jwt.resource.normalize  // strip any leading or trailing spaces, and convert to null in case those were the only content
        // create a session
        val session = new SessionDTO => [
            sessionId           = jwt.sessionId
            objectRef           = jwt.sessionRef
            locale              = jwt.locale
            zoneinfo            = jwt.zoneinfo
            userRef             = new UserRef(jwt.userRef)
            tenantRef           = new TenantRef(jwt.tenantRef)
            if (sp !== null) {
                // memorize session parameters
                locale          = sp.locale
                userAgent       = sp.userAgent
                dataUri         = sp.dataUri
                zoneinfo        = sp.zoneinfo
            }
            if (continuesFromJwt !== null) {
                // transition reference to prior session
                continuesFromSession = continuesFromJwt.sessionRef
            }
        ]

        persistenceAccess.storeSession(session)

        LOGGER.debug("About to sign the following Jwt: {}", ToStringHelper.toStringML(jwt))
        return authenticator.doSign(jwt)
    }
}
