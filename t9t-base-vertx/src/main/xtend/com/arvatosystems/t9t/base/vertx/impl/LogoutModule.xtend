package com.arvatosystems.t9t.base.vertx.impl

import com.arvatosystems.t9t.base.api.ServiceResponse
import com.arvatosystems.t9t.base.vertx.IServiceModule
import de.jpaw.annotations.AddLogger
import de.jpaw.bonaparte.api.codecs.IMessageCoderFactory
import de.jpaw.bonaparte.core.BonaPortable
import de.jpaw.dp.Dependent
import de.jpaw.dp.Named
import io.vertx.core.Vertx
import io.vertx.ext.web.Router

/** This path provides for server side connection closes in order to avoid messages such as
 * Feb 27, 2016 2:44:53 PM io.vertx.core.net.impl.ConnectionBase
 * SEVERE: java.io.IOException: Connection reset by peer
 * which occur when the client closes the connection.
 * It can be used to invalidate the JWT as well.
 */
@Named("logout")
@Dependent
@AddLogger
class LogoutModule implements IServiceModule {
    override getExceptionOffset() {
        return 10_000
    }

    override getModuleName() {
        return "logout"
    }

    override void mountRouters(Router router, Vertx vertx, IMessageCoderFactory<BonaPortable, ServiceResponse, byte[]> coderFactory) {
        LOGGER.info("Registering module {}", moduleName)
        router.post("/logout").handler [
            LOGGER.debug("POST /logout received")
            response.end
            response.close
        ]
    }
}
