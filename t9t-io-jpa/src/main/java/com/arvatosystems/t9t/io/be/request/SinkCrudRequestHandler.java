package com.arvatosystems.t9t.io.be.request;

import com.arvatosystems.t9t.base.T9tException;
import com.arvatosystems.t9t.base.api.ServiceResponse;
import com.arvatosystems.t9t.base.entities.FullTracking;
import com.arvatosystems.t9t.base.jpa.impl.AbstractCrudSurrogateKey42RequestHandler;
import com.arvatosystems.t9t.io.CommunicationTargetChannelType;
import com.arvatosystems.t9t.io.SinkDTO;
import com.arvatosystems.t9t.io.SinkRef;
import com.arvatosystems.t9t.io.T9tIOException;
import com.arvatosystems.t9t.io.jpa.entities.SinkEntity;
import com.arvatosystems.t9t.io.jpa.mapping.ISinkDTOMapper;
import com.arvatosystems.t9t.io.jpa.persistence.ISinkEntityResolver;
import com.arvatosystems.t9t.io.request.SinkCrudRequest;

import de.jpaw.dp.Jdp;

public class SinkCrudRequestHandler extends AbstractCrudSurrogateKey42RequestHandler<SinkRef, SinkDTO, FullTracking, SinkCrudRequest, SinkEntity> {

    private static final String[] FORBIDDEN_FILE_PATH_ELEMENTS = { ":", "\\", "../" };

//  @Inject
    private final ISinkEntityResolver sinksResolver = Jdp.getRequired(ISinkEntityResolver.class);
//  @Inject
    private final ISinkDTOMapper sinksMapper = Jdp.getRequired(ISinkDTOMapper.class);

    @Override
    public ServiceResponse execute(SinkCrudRequest crudRequest) throws Exception {
        return execute(sinksMapper, sinksResolver, crudRequest);
    }

    @Override
    protected final void validateUpdate(SinkEntity current, SinkDTO intended) {
        if (intended.getCommTargetChannelType().equals(CommunicationTargetChannelType.FILE)) {
            validateFilePathPattern(intended.getFileOrQueueName());
        }
    }

    @Override
    protected final void validateCreate(SinkDTO intended) {
        if (intended.getCommTargetChannelType().equals(CommunicationTargetChannelType.FILE)) {
            validateFilePathPattern(intended.getFileOrQueueName());
        }
    }

    private void validateFilePathPattern(String pattern) {
        for (String vorbiddenElement : FORBIDDEN_FILE_PATH_ELEMENTS) {
            if (pattern.contains(vorbiddenElement)) {
                throw new T9tException(T9tIOException.FORBIDDEN_FILE_PATH_ELEMENTS);
            }
        }

        if (pattern.startsWith("/")) {
            throw new T9tException(T9tIOException.FORBIDDEN_FILE_PATH_ELEMENTS);
        }
    }
}
