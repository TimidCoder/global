package com.arvatosystems.t9t.auth.be.impl;

import com.arvatosystems.t9t.auth.TenantDTO
import com.arvatosystems.t9t.auth.UserDTO
import com.arvatosystems.t9t.base.T9tConstants
import de.jpaw.bonaparte.pojos.api.auth.JwtInfo
import de.jpaw.bonaparte.pojos.api.auth.Permissionset
import de.jpaw.bonaparte.pojos.api.auth.UserLogLevelType

/** Utility class to provide default UserDTO and TenantDTO in case no other suitable instances are available. */
public class T9tDefaultContext {

    public static final JwtInfo DEFAULT_JWT = new JwtInfo => [
        userId             = T9tConstants.TECHNICAL_USER_ID
        userRef            = T9tConstants.TECHNICAL_USER_REF42
        logLevel           = UserLogLevelType.STEALTH
        logLevelErrors     = UserLogLevelType.MESSAGE_ENTRY
        name               = "t9t system user"
        locale             = "en-US"
        freeze
    ]

    public static final TenantDTO DEFAULT_TENANT_DTO = new TenantDTO => [
        objectRef           = T9tConstants.GLOBAL_TENANT_REF42
        tenantId            = T9tConstants.GLOBAL_TENANT_ID
        isActive            = true
        name                = "Global tenant"
        freeze
    ]

    public static final UserDTO DEFAULT_USER_DTO = new UserDTO => [
        objectRef           = T9tConstants.TECHNICAL_USER_REF42
        userId              = T9tConstants.TECHNICAL_USER_ID
        isActive            = true
        name                = "t9t system user"
        freeze
    ]

    public static final UserDTO STARTUP_USER_DTO = new UserDTO => [
        objectRef           = T9tConstants.STARTUP_USER_REF42
        userId              = T9tConstants.STARTUP_USER_ID
        isActive            = true
        name                = "t9t system bootstrap user"
        freeze
    ]

    public static final JwtInfo STARTUP_JWT = new JwtInfo => [
        userRef             = T9tConstants.STARTUP_USER_REF42
        userId              = T9tConstants.STARTUP_USER_ID
        tenantRef           = T9tConstants.GLOBAL_TENANT_REF42
        tenantId            = T9tConstants.GLOBAL_TENANT_ID
        logLevel            = UserLogLevelType.STEALTH
        logLevelErrors      = UserLogLevelType.MESSAGE_ENTRY
        resource            = "-"
        permissionsMin      = new Permissionset(0)
        permissionsMax      = new Permissionset(0)
        name                = "t9t system bootstrap user"
        locale              = "en-US"
        zoneinfo            = "UTC"
    ]
}
