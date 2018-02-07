package com.arvatosystems.t9t.io.be.request;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.arvatosystems.t9t.base.api.ServiceResponse;
import com.arvatosystems.t9t.base.output.ExportStatusEnum;
import com.arvatosystems.t9t.base.services.AbstractRequestHandler;
import com.arvatosystems.t9t.base.services.IFileUtil;
import com.arvatosystems.t9t.base.services.RequestContext;
import com.arvatosystems.t9t.io.T9tIOException;
import com.arvatosystems.t9t.io.jpa.entities.SinkEntity;
import com.arvatosystems.t9t.io.jpa.mapping.IDataSinkDTOMapper;
import com.arvatosystems.t9t.io.jpa.persistence.ISinkEntityResolver;
import com.arvatosystems.t9t.io.request.ProcessCamelRouteRequest;
import com.arvatosystems.t9t.out.services.IFileToCamelProducer;

import de.jpaw.bonaparte.api.media.MediaTypeInfo;
import de.jpaw.bonaparte.pojos.api.media.MediaTypeDescriptor;
import de.jpaw.dp.Jdp;
import de.jpaw.util.ExceptionUtil;

public class ProcessCamelRouteRequestHandler extends AbstractRequestHandler<ProcessCamelRouteRequest> {
    private static final Logger LOGGER = LoggerFactory.getLogger(ProcessCamelRouteRequestHandler.class);
    protected static final String GZIP_EXTENSION = ".gz";

    protected final IFileUtil fileUtil = Jdp.getRequired(IFileUtil.class);
    protected final IFileToCamelProducer fileToCamelProducer = Jdp.getRequired(IFileToCamelProducer.class);
    protected final ISinkEntityResolver sinkResolver = Jdp.getRequired(ISinkEntityResolver.class);
    protected final IDataSinkDTOMapper dataSinkMapper = Jdp.getRequired(IDataSinkDTOMapper.class);

    @Override
    public ServiceResponse execute(RequestContext ctx, ProcessCamelRouteRequest rq) throws Exception {
        final SinkEntity sink = sinkResolver.getEntityDataForKey(rq.getSinkRef(), false);
        if (sink.getCamelTransferStatus() == ExportStatusEnum.RESPONSE_OK) {
            LOGGER.info("Sink {} for {} was already transferred - skipping", rq.getSinkRef(), sink.getFileOrQueueName());
            return ok();
        }
        String absolutePath = fileUtil.getAbsolutePathForTenant(ctx.tenantId, sink.getFileOrQueueName());

        if (sink.getDataSink().getCompressed()) {
            // if it's compressed but the file name doesn't seem to have GZIP extension, append it
            if (!absolutePath.toLowerCase().endsWith(GZIP_EXTENSION)) {
                absolutePath += GZIP_EXTENSION;
            }
        }
        MediaTypeDescriptor mediaType = MediaTypeInfo.getFormatByType(sink.getCommFormatType());
        LOGGER.info("Transferring sink {} as {} for path {}", rq.getSinkRef(), mediaType, absolutePath);
        try {
            fileToCamelProducer.sendFileOverCamel(absolutePath, mediaType, dataSinkMapper.mapToDto(sink.getDataSink()));
            // assuming the transfer was successful if we did not get an exception here, mark the sink as transferred
            sink.setCamelTransferStatus(ExportStatusEnum.RESPONSE_OK);
        } catch (Exception e) {
            LOGGER.error("Camel transfer failed: {}", ExceptionUtil.causeChain(e));
            sink.setCamelTransferStatus(ExportStatusEnum.RESPONSE_ERROR);
            return ok(T9tIOException.NOT_TRANSFERRED);
        }
        return ok();
    }
}
