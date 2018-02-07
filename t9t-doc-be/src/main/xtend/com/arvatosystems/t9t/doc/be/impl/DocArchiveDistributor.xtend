package com.arvatosystems.t9t.doc.be.impl

import com.arvatosystems.t9t.base.output.OutputSessionParameters
import com.arvatosystems.t9t.base.services.IOutputSession
import com.arvatosystems.t9t.doc.T9tDocException
import com.arvatosystems.t9t.doc.T9tDocExtException
import com.arvatosystems.t9t.doc.api.DocumentSelector
import com.arvatosystems.t9t.doc.recipients.RecipientArchive
import com.arvatosystems.t9t.doc.services.IDocArchiveDistributor
import de.jpaw.annotations.AddLogger
import de.jpaw.bonaparte.api.media.MediaTypes
import de.jpaw.bonaparte.core.MapComposer
import de.jpaw.bonaparte.pojos.api.media.MediaData
import de.jpaw.bonaparte.pojos.api.media.MediaXType
import de.jpaw.dp.Jdp
import de.jpaw.dp.Singleton
import java.io.IOException
import java.io.OutputStream
import java.util.HashMap
import java.util.function.Function
import com.arvatosystems.t9t.doc.services.DocArchiveResult

@Singleton
@AddLogger
class DocArchiveDistributor implements IDocArchiveDistributor {

    override transmit(RecipientArchive rcpt, Function<MediaXType, MediaData> data, MediaXType primaryFormat, String documentTemplateId, DocumentSelector documentSelector) {

        val outputSession           = Jdp.getRequired(IOutputSession);
        val additionalParams        = new HashMap<String,Object>(8)
        MapComposer.marshal(documentSelector, false, false).forEach[name, value | additionalParams.put(name, value.toString)]
        val sessionParams           = new OutputSessionParameters => [
            dataSinkId              = rcpt.dataSinkId
            originatorRef           = rcpt.originatorRef
            configurationRef        = rcpt.configurationRef
            genericRefs1            = rcpt.genericRefs1
            genericRefs2            = rcpt.genericRefs2
            communicationFormatType = rcpt.communicationFormat ?: MediaTypes.MEDIA_XTYPE_UNDEFINED
            additionalParameters    = additionalParams
            additionalParameters.put("documentTemplateId", documentTemplateId)
            additionalParameters.putAll(rcpt.outputSessionParameters)
        ]

        // where to assign in output session? TODO
        var OutputStream outputStream = null;
        try {
            //open
            val sinkRef = outputSession.open(sessionParams);

            // check if conversion required
            val requestedType = outputSession.communicationFormatType
            var documentForStream = data.apply(requestedType)
            outputStream = outputSession.outputStream

            if (documentForStream.rawData !== null)
                documentForStream.rawData.toOutputStream(outputStream)
            else if (documentForStream.text !== null)
               outputStream.write(documentForStream.text.getBytes("UTF-8"));

            val fileOrQueueName = outputSession.fileOrQueueName
            outputStream.close
            outputStream = null
            return new DocArchiveResult(sinkRef, fileOrQueueName)
        } catch (IOException e) {
            LOGGER.error("Unable to open the output session or write to it, due to : {} ", e);
            throw new T9tDocException(T9tDocExtException.DOCUMENT_CREATION_ERROR);
        } finally {
            try {
                if (outputStream !== null) {
                    outputStream.close();
                }
                if (outputSession !== null) {
                    outputSession.close();
                }
            } catch (Exception e) {
                LOGGER.error("Unable to close the resources, due to : {} ", e);
//                    throw new T9tDocException(T9tDocException.DOCUMENT_CREATION_ERROR);
            }
        }
    }
}
