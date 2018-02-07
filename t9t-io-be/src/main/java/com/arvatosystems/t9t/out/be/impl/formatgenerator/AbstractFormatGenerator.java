package com.arvatosystems.t9t.out.be.impl.formatgenerator;

import java.io.IOException;
import java.nio.charset.Charset;

import com.arvatosystems.t9t.base.output.OutputSessionParameters;
import com.arvatosystems.t9t.io.DataSinkDTO;
import com.arvatosystems.t9t.io.T9tIOException;
import com.arvatosystems.t9t.out.be.ICommunicationFormatGenerator;
import com.arvatosystems.t9t.out.be.impl.output.FoldableParams;
import com.arvatosystems.t9t.out.services.IOutputResource;

import de.jpaw.bonaparte.core.BonaPortable;
import de.jpaw.bonaparte.pojos.api.media.MediaXType;
import de.jpaw.util.ApplicationException;

public abstract class AbstractFormatGenerator implements ICommunicationFormatGenerator {

    protected IOutputResource outputResource = null;
    protected MediaXType effectiveType;
    protected DataSinkDTO sinkCfg;
    protected OutputSessionParameters outputSessionParameters;
    protected Charset encoding;
    protected FoldableParams foldableParams;
    protected String tenantId;

    protected void openHook() throws IOException, ApplicationException {
        if (foldableParams != null) {
            throw new T9tIOException(T9tIOException.NO_FOLDING_SUPPORT, effectiveType.name());
        }
    }

    @Override
    public void open(DataSinkDTO sinkCfg, OutputSessionParameters outputSessionParameters, MediaXType effectiveType, FoldableParams foldableParams, IOutputResource destination, Charset encoding,
            String tenantId) throws IOException, ApplicationException {
        this.outputResource = destination;
        this.effectiveType = effectiveType;
        this.sinkCfg = sinkCfg;
        this.outputSessionParameters = outputSessionParameters;
        this.encoding = encoding;
        this.foldableParams = foldableParams;
        this.tenantId = tenantId;
        openHook();
    }

    @Override
    public void generateData(int recordNo, int mappedRecordNo, long recordId, BonaPortable record) throws IOException, ApplicationException {
        throw new T9tIOException(T9tIOException.NO_RECORD_BASED_OUTPUT, effectiveType.name());
    }

    @Override
    public void close() throws IOException, ApplicationException {
        outputResource = null;
    }
}
