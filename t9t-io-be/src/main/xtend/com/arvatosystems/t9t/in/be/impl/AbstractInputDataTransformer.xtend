package com.arvatosystems.t9t.in.be.impl

import com.arvatosystems.t9t.in.services.IInputDataTransformer
import com.arvatosystems.t9t.in.services.IInputSession
import com.arvatosystems.t9t.io.DataSinkDTO
import com.arvatosystems.t9t.server.services.IStatefulServiceSession
import de.jpaw.bonaparte.core.BonaPortable
import de.jpaw.bonaparte.core.BonaPortableClass
import java.util.Map

abstract class AbstractInputDataTransformer<T extends BonaPortable> implements IInputDataTransformer<T> {
    protected IInputSession inputSession;
    protected DataSinkDTO   cfg;
    protected BonaPortableClass<?> baseBClass

    override open(IInputSession inputSession, DataSinkDTO sinkCfg, IStatefulServiceSession session, Map<String, Object> params, BonaPortableClass<?> baseBClass) {
        this.inputSession    = inputSession
        this.cfg             = sinkCfg
        this.baseBClass      = baseBClass
    }
}
