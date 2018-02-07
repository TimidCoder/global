package com.arvatosystems.t9t.core.be.request

import com.arvatosystems.t9t.base.request.ComponentInfoDTO
import com.arvatosystems.t9t.base.request.RetrieveComponentInfoRequest
import com.arvatosystems.t9t.base.request.RetrieveComponentInfoResponse
import com.arvatosystems.t9t.base.search.ReadAllResponse
import com.arvatosystems.t9t.base.services.AbstractSearchRequestHandler
import com.arvatosystems.t9t.base.services.IExecutor
import com.arvatosystems.t9t.base.services.IExporterTool
import com.arvatosystems.t9t.base.services.RequestContext
import com.arvatosystems.t9t.core.request.ComponentInfoSearchRequest
import com.google.common.collect.ImmutableList
import de.jpaw.bonaparte.pojos.api.AndFilter
import de.jpaw.bonaparte.pojos.api.NoTracking
import de.jpaw.bonaparte.pojos.api.SearchFilter
import de.jpaw.bonaparte.pojos.api.SortColumn
import de.jpaw.bonaparte.pojos.api.UnicodeFilter
import de.jpaw.bonaparte.pojos.apiw.DataWithTrackingW
import de.jpaw.dp.Inject
import java.util.ArrayList
import java.util.Collections
import java.util.List

class ComponentInfoSearchRequestHandler extends AbstractSearchRequestHandler<ComponentInfoSearchRequest> {
    @Inject protected IExecutor executor
    @Inject protected IExporterTool<ComponentInfoDTO, NoTracking> exporter

    def protected List<ComponentInfoDTO> applyFilters(SearchFilter it, List<ComponentInfoDTO> input) {
        switch it {
            AndFilter: return filter1.applyFilters(filter2.applyFilters(input))
            UnicodeFilter:
                if (equalsValue !== null) {
                    if (fieldName == "groupId")
                        return input.filter[dto | dto.groupId == equalsValue].toList
                    else if (fieldName == "artifactId")
                        return input.filter[dto | dto.artifactId == equalsValue].toList
                } else if (likeValue !== null) {
                    val like = if (likeValue.endsWith("%")) likeValue.substring(0, likeValue.length - 1) else likeValue
                    if (fieldName == "groupId")
                        return input.filter[dto | dto.groupId.startsWith(like)].toList
                    else if (fieldName == "artifactId")
                        return input.filter[dto | dto.artifactId.startsWith(like)].toList
                }
        }
    }

    def protected List<ComponentInfoDTO> reverse(List<ComponentInfoDTO> input, boolean reverse) {
        if (reverse) {
            val tmp = new ArrayList<ComponentInfoDTO>(input);
            Collections.reverse(tmp)
            return tmp
        } else {
            return input
        }
    }

    def protected List<ComponentInfoDTO> applySort(SortColumn it, List<ComponentInfoDTO> input) {
        switch (fieldName) {
            case "groupId":       return input.sortBy[groupId].reverse(descending)
            case "artifactId":    return input.sortBy[artifactId].reverse(descending)
            case "versionString": return input.sortBy[versionString].reverse(descending)
            case "commitId":      return input.sortBy[commitId ?: "x"].reverse(descending)
        }
    }

    def protected <E> List<E> cut(List<E> input, int offset, int limit) {
        if (offset == 0 && limit == 0)
            return input;
        if (limit == 0) {
            // offset to end...
            if (offset >= input.size)
                return ImmutableList.of  // empty...
            return input.subList(offset, input.size)
        }
        if (offset >= input.size)
            return ImmutableList.of  // empty...
        if (offset + limit >= input.size)
            return input.subList(offset, input.size)  // offset to end
        return input.subList(offset, offset + limit)
    }

    override ReadAllResponse<ComponentInfoDTO, NoTracking> execute(RequestContext ctx, ComponentInfoSearchRequest rq) {
        // map generic search filters to the specific parameters
        val cmd = new RetrieveComponentInfoRequest
        val components   = executor.executeSynchronousAndCheckResult(ctx, cmd, RetrieveComponentInfoResponse).components
        val filteredList = if (rq.searchFilter === null)   components   else rq.searchFilter.applyFilters(components)
        val sortedList   = if (rq.sortColumns.nullOrEmpty) filteredList else rq.sortColumns.get(0).applySort(filteredList)
        val limitedList  = sortedList.cut(rq.offset, rq.limit)
        val dataList     = new ArrayList<DataWithTrackingW<ComponentInfoDTO, NoTracking>>(limitedList.size)
        for (dto: limitedList) {
            val dwt = new DataWithTrackingW<ComponentInfoDTO, NoTracking>
            dwt.data = dto
            dwt.tenantRef = ctx.tenantRef  // avoid having null here
            dataList.add(dwt)
        }
        return exporter.returnOrExport(dataList, rq.getSearchOutputTarget());
    }
}
