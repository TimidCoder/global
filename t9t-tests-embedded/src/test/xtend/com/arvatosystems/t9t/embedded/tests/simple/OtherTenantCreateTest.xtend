package com.arvatosystems.t9t.embedded.tests.simple

import com.arvatosystems.t9t.auth.tests.setup.SetupUserTenantRole
import com.arvatosystems.t9t.base.ITestConnection
import com.arvatosystems.t9t.base.search.ReadAllResponse
import com.arvatosystems.t9t.embedded.connect.InMemoryConnection
import com.arvatosystems.t9t.io.CommunicationTargetChannelType
import com.arvatosystems.t9t.io.DataSinkCategoryType
import com.arvatosystems.t9t.io.DataSinkDTO
import com.arvatosystems.t9t.io.request.DataSinkSearchRequest
import de.jpaw.bonaparte.pojos.api.media.MediaType
import java.util.UUID
import org.junit.BeforeClass
import org.junit.Test

import static extension com.arvatosystems.t9t.misc.extensions.MiscExtensionsCreate.*
import org.junit.Assert
import de.jpaw.bonaparte.pojos.api.AsciiFilter

class OtherTenantCreateTest {

    static private ITestConnection dlg

    @BeforeClass
    def public static void createConnection() {
        // use a single connection for all tests (faster)
        dlg = new InMemoryConnection
    }

    def private createDataSink(String name) {
        new DataSinkDTO => [
            dataSinkId              = name
            isActive                = true
            isInput                 = false
            commTargetChannelType   = CommunicationTargetChannelType.FILE
            commFormatType          = MediaType.HTML
            fileOrQueueNamePattern  = name + ".html"
            category                = DataSinkCategoryType.CUSTOMER_COMMUNICATION
            create(dlg)
        ]
    }

    @Test
    def public void create2TenantsTest() {
    val myDataSinkId = "blaCreate"
        // create an entry for the global tenant
        createDataSink(myDataSinkId)

        val setup = new SetupUserTenantRole(dlg)
        setup.createUserTenantRole("dirtyHarry", UUID.randomUUID, true)

        createDataSink(myDataSinkId)

        val dataSinks = dlg.typeIO((new DataSinkSearchRequest => [
        searchFilter = new AsciiFilter => [
        fieldName    = "dataSinkId"
        equalsValue  = myDataSinkId
        ]
        ] ), ReadAllResponse)
        Assert.assertEquals(2, dataSinks.dataList.size)
    }
}
