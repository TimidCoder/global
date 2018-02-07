package com.arvatosystems.t9t.exceptions.tests

import com.arvatosystems.t9t.base.ITestConnection
import com.arvatosystems.t9t.embedded.connect.InMemoryConnection
import de.jpaw.annotations.AddLogger
import org.junit.Assert
import org.junit.BeforeClass
import org.junit.Test

@AddLogger
class TestExceptionCodes {

    static private ITestConnection dlg

    @BeforeClass
    def public static void createConnection() {
        // use a single connection for all tests (faster)
        dlg = new InMemoryConnection
    }


    @Test
    def void checkAllExceptions() {
        // first, actively load all exception classes (among others)
        LOGGER.info("Skipping Init")
        //Init.initializeT9t // Init removed because it will be initialized with the inmemoryConnection instead

        // check exception codes
        Assert.assertTrue(JustATrickToAccessCodeToDescription.validateAllExceptions)
    }
}
