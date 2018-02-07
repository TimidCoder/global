package com.arvatosystems.t9t.embedded.tests.simple

import com.arvatosystems.t9t.base.ITestConnection
import com.arvatosystems.t9t.base.crud.CrudSurrogateKeyResponse
import com.arvatosystems.t9t.base.request.BatchRequest
import com.arvatosystems.t9t.base.request.LogMessageRequest
import com.arvatosystems.t9t.base.request.PauseRequest
import com.arvatosystems.t9t.core.CannedRequestDTO
import com.arvatosystems.t9t.core.CannedRequestRef
import com.arvatosystems.t9t.embedded.connect.InMemoryConnection
import com.arvatosystems.t9t.ssm.SchedulerSetupDTO
import com.arvatosystems.t9t.ssm.SchedulerSetupKey
import com.arvatosystems.t9t.ssm.SchedulerSetupRecurrenceType
import com.arvatosystems.t9t.ssm.request.ClearAllRequest
import com.arvatosystems.t9t.ssm.request.SchedulerSetupCrudRequest
import de.jpaw.bonaparte.pojos.api.OperationType
import org.junit.BeforeClass
import org.junit.Test
import static extension com.arvatosystems.t9t.misc.extensions.MiscExtensions.*

class CannedRequest2Test {
    val REQUEST_ID      = "myPause"
    val SCHEDULER_ID    = "fastPause"
    static private ITestConnection dlg

    @BeforeClass
    def public static void createConnection() {
        // use a single connection for all tests (faster)
        dlg = new InMemoryConnection
    }

    @Test
    def public void fastTriggerSchedulerTest() {

        dlg.doIO(new ClearAllRequest)

        // batched task is a job to perform a log request, a pause, and another log, all in the same transaction
        val batchedTask = new BatchRequest => [
            commands = #[
                new LogMessageRequest("Hello BEFORE pause"),
                new PauseRequest => [
                    delayInMillis   = 4500
                ],
                new LogMessageRequest("Hello AFTER pause")
            ]
        ]

        val cannedRequestDTO = new CannedRequestDTO => [
            requestId                   = REQUEST_ID
            name                        = "pause request for test"
            // jobRequestObjectName        = batchedTask.ret$PQON
            // jobParameters               = #{ "delayInMillis" -> 4500 }
            request                     = batchedTask
        ]
//        val requestRef  = (dlg.typeIO(new CannedRequestCrudRequest => [
//            crud        = OperationType.MERGE
//            data        = cannedRequestDTO
//            naturalKey  = new CannedRequestKey(REQUEST_ID)
//        ], CrudSurrogateKeyResponse)).key
        val requestRef = cannedRequestDTO.merge(dlg).key

        val cfg = new SchedulerSetupDTO => [
            schedulerId                 = SCHEDULER_ID
            isActive                    = true
            userId                      = "admin"
            languageCode                = "en"
            name                        = "Pause request: 4 times pause of 4.5 seconds"
            recurrencyType              = SchedulerSetupRecurrenceType.FAST
            request                     = new CannedRequestRef(requestRef)
            repeatCount                 = 4
            intervalMilliseconds        = 500L
        ]

        // delete any old record to ensure we set up a new one. Ignore the result
        val key = new SchedulerSetupKey(SCHEDULER_ID)
        dlg.doIO(new SchedulerSetupCrudRequest => [
            crud        = OperationType.DELETE
            naturalKey  = key
        ])

        // create a new scheduler
        dlg.typeIO(new SchedulerSetupCrudRequest => [
            crud = OperationType.CREATE
            data = cfg
        ], CrudSurrogateKeyResponse)
    }

}
