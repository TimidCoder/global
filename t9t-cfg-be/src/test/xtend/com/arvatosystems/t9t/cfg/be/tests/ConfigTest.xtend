package com.arvatosystems.t9t.cfg.be.tests

import com.arvatosystems.t9t.cfg.be.ConfigProvider
import org.junit.Test
import static org.junit.Assert.*
import com.arvatosystems.t9t.cfg.be.T9tServerConfiguration
import org.junit.Ignore
import com.arvatosystems.t9t.cfg.be.ApplicationConfiguration

public class ConfigTest {

    @Ignore  // do not do file output in regression runs
    @Test
    def void writeConfig() {
        val cfg = ConfigProvider.configuration
        cfg.applicationConfiguration = new ApplicationConfiguration => [
            workerPoolSize = 40
            maxWorkerExecuteTime = 43200
        ]
        ConfigProvider.configToFile(cfg, "/tmp/t9tconfig.xml");   // the file in user's home is ~/.t9tconfig.xml
    }

    // example for an AWS RDS DB URL
    val testCfg = '''
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <T9tServerConfiguration xmlns="http://arvatosystems.com/schema/t9t_cfg_be.xsd">
            <persistenceUnitName>t9t-DS</persistenceUnitName>
            <databaseConfiguration>
                <username>fortytwo</username>
                <password>secret</password>
                <databaseBrand>POSTGRES</databaseBrand>
                <jdbcConnectString>jdbc:postgresql://t9t.cxxssfrkkvid.eu-central-1.rds.amazonaws.com:5432/t9tdb</jdbcConnectString>
            </databaseConfiguration>
            <awsConfiguration>
                <snsEndpoint>https://sns.eu-central-1.amazonaws.com</snsEndpoint>
                <sqsEndpoint>https://sqs.eu-central-1.amazonaws.com</sqsEndpoint>
            </awsConfiguration>
        </T9tServerConfiguration>
    '''

    @Test
    def void readConfig() {
        val cfg = ConfigProvider.configFromString(testCfg)
        assertNotNull(cfg)
        assertEquals(T9tServerConfiguration, cfg.class)
        assertNotNull(cfg.databaseConfiguration)
        assertNotNull(cfg.awsConfiguration)
        assertNull(cfg.bpmConfiguration)

        assertEquals("secret", cfg.databaseConfiguration.password)
    }
}
