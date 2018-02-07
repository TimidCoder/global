package com.arvatosystems.t9t.embedded.tests.translation

import com.arvatosystems.t9t.base.ITestConnection
import com.arvatosystems.t9t.embedded.connect.InMemoryConnection
import com.arvatosystems.t9t.init.UiGridConfigPrefs
import de.jpaw.annotations.AddLogger
import org.junit.BeforeClass
import org.junit.Test

@AddLogger
class GridConfigValidationTest {
    static private ITestConnection dlg

    @BeforeClass
    def public static void createConnection() {
        // use a single connection for all tests (faster)
        dlg = new InMemoryConnection
    }

    @Test
    def public void gridConfigTest() {
        val errors = UiGridConfigPrefs.errorCount
        if (errors !== 0) {
            LOGGER.error("There are {} grid config errors", errors)
            throw new RuntimeException("Grid config is not correct")
        } else {
            LOGGER.info("Grid config validated and OK")
        }
    }
}
