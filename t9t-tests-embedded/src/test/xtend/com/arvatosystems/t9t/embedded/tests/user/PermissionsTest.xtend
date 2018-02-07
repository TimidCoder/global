package com.arvatosystems.t9t.embedded.tests.user

import com.arvatosystems.t9t.auth.PermissionsDTO
import com.arvatosystems.t9t.auth.RoleKey
import com.arvatosystems.t9t.auth.RoleToPermissionDTO
import com.arvatosystems.t9t.auth.request.RoleToPermissionCrudRequest
import com.arvatosystems.t9t.auth.tests.setup.SetupUserTenantRole
import com.arvatosystems.t9t.authz.api.QueryPermissionsRequest
import com.arvatosystems.t9t.authz.api.QueryPermissionsResponse
import com.arvatosystems.t9t.authz.api.QuerySinglePermissionRequest
import com.arvatosystems.t9t.authz.api.QuerySinglePermissionResponse
import com.arvatosystems.t9t.base.ITestConnection
import com.arvatosystems.t9t.base.auth.PermissionEntry
import com.arvatosystems.t9t.base.auth.PermissionType
import com.arvatosystems.t9t.embedded.connect.InMemoryConnection
import de.jpaw.bonaparte.pojos.api.OperationType
import de.jpaw.bonaparte.pojos.api.auth.Permissionset
import de.jpaw.bonaparte.pojos.api.auth.UserLogLevelType
import de.jpaw.bonaparte.util.ToStringHelper
import java.util.UUID
import org.junit.Assert
import org.junit.BeforeClass
import org.junit.Test

class PermissionsTest {
    static private ITestConnection dlg
    static private final String myPermissionId = "U.testperm-id.x"

    static private class MySetup extends SetupUserTenantRole {
        new(ITestConnection dlg) {
            super(dlg)
        }
        override getPermissionDTO() {
            return new PermissionsDTO => [
                logLevel            = UserLogLevelType.REQUESTS
                logLevelErrors      = UserLogLevelType.REQUESTS
                minPermissions      = Permissionset.of(OperationType.LOOKUP)
                maxPermissions      = ALL_PERMISSIONS
                resourceIsWildcard  = Boolean.TRUE
                resourceRestriction = "B.,"
            ]
        }
    }

    @BeforeClass
    def public static void createConnection() {
        // use a single connection for all tests (faster)
        dlg = new InMemoryConnection;
        (new MySetup(dlg)).createUserTenantRole("testPerm", UUID.randomUUID, true)

        val rtp = new RoleToPermissionDTO => [
            roleRef          = new RoleKey("testPerm")
            permissionId     = myPermissionId
            permissionSet    = Permissionset.of(OperationType.CONTEXT)
            validate
        ]
        dlg.okIO(new RoleToPermissionCrudRequest => [
            crud = OperationType.CREATE
            data = rtp
        ])
    }

    @Test
    def public void QueryPermissionsTest() {
        val result = dlg.typeIO(new QueryPermissionsRequest(PermissionType.FRONTEND), QueryPermissionsResponse)
        println('''Result is «ToStringHelper.toStringML(result)»''')
        Assert.assertEquals(result.permissions.size, 1)
        Assert.assertEquals(new PermissionEntry(myPermissionId, Permissionset.of(OperationType.CONTEXT, OperationType.LOOKUP)), result.permissions.get(0))
    }

    @Test
    def public void QuerySinglePermissionTest() {
        val result = dlg.typeIO(new QuerySinglePermissionRequest(PermissionType.FRONTEND, "testperm-id.x"), QuerySinglePermissionResponse)
        println('''Result is «ToStringHelper.toStringML(result)»''')
        Assert.assertEquals(Permissionset.of(OperationType.CONTEXT, OperationType.LOOKUP), result.permissions)
    }

    @Test
    def public void QueryAnotherSinglePermissionTest() {
        val result = dlg.typeIO(new QuerySinglePermissionRequest(PermissionType.FRONTEND, "no-perm"), QuerySinglePermissionResponse)
        println('''Result is «ToStringHelper.toStringML(result)»''')
        Assert.assertEquals(Permissionset.of(), result.permissions)
    }
}
