package com.arvatosystems.t9t.embedded.tests.events

import com.arvatosystems.t9t.base.ITestConnection
import com.arvatosystems.t9t.bucket.request.BucketEntrySearchRequest
import com.arvatosystems.t9t.bucket.request.SingleBucketWriteRequest
import com.arvatosystems.t9t.embedded.connect.InMemoryConnection
import de.jpaw.bonaparte.pojos.api.AsciiFilter
import org.junit.BeforeClass
import org.junit.Test
import com.arvatosystems.t9t.base.search.ReadAllResponse
import org.junit.Assert

class BucketWritingTest {
    static private ITestConnection dlg

    @BeforeClass
    def public static void createConnection() {
        // use a single connection for all tests (faster)
        dlg = new InMemoryConnection
    }

    def protected void searchBucket(String qualifier) {
        val rq = new BucketEntrySearchRequest => [
            searchFilter        = new AsciiFilter("qualifier") => [
                equalsValue     = qualifier
            ]
        ]
        val rs = dlg.typeIO(rq, ReadAllResponse)
        Assert.assertEquals(1, rs.dataList.size)
    }

    @Test
    def public void performDirectBucketWritingTest() {
        val rq = new SingleBucketWriteRequest => [
            async                   = false
            objectRef               = 424242L
            values                  = #{ 'XYZ' -> 3 }
        ]
        dlg.okIO(rq)
        Thread.sleep(1000)  // wait for async request to be executed
        searchBucket('XYZ')
    }

    @Test
    def public void performAsyncBucketWritingTest() {
        val rq = new SingleBucketWriteRequest => [
            async                   = true
            objectRef               = 424242L
            values                  = #{ 'ASY' -> 3 }
        ]
        dlg.okIO(rq)
        Thread.sleep(1000)  // wait for async request to be executed
        searchBucket('ASY')
    }
}
