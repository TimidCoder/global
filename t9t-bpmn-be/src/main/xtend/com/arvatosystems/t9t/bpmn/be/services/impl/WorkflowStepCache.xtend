package com.arvatosystems.t9t.bpmn.be.services.impl

import com.arvatosystems.t9t.bpmn.IBPMObjectFactory
import com.arvatosystems.t9t.bpmn.IWorkflowStep
import com.arvatosystems.t9t.bpmn.T9tBPMException
import com.arvatosystems.t9t.bpmn.services.IWorkflowStepCache
import de.jpaw.annotations.AddLogger
import de.jpaw.dp.Jdp
import de.jpaw.dp.Singleton
import java.util.Map
import com.google.common.collect.ImmutableMap

@AddLogger
@Singleton
class WorkflowStepCache implements IWorkflowStepCache {
    private Map<String, IWorkflowStep> workflowSteps = null
    private Map<String, IBPMObjectFactory> bpmObjectFactories = null

    override loadCaches() {
        try {
            workflowSteps = Jdp.getInstanceMapPerQualifier(IWorkflowStep)
            bpmObjectFactories = Jdp.getInstanceMapPerQualifier(IBPMObjectFactory)
        } catch (Exception e) {
            LOGGER.error("Initializer exception due to ", e)
        }

        LOGGER.info("Found {} BPM object factories and {} BPM workflow step implementations", bpmObjectFactories.size(), workflowSteps.size())
        for (of : bpmObjectFactories.entrySet) {
            LOGGER.debug("BPM object factory {} is implemented by {}", of.key, of.value.class.canonicalName)
        }
        for (ws : workflowSteps.entrySet) {
            val factory = ws.value.factoryName
            val factoryExists = factory === null || bpmObjectFactories.get(factory) !== null
            if (LOGGER.isDebugEnabled) {
                val factoryText = if (factory !== null) {
                    " (using factory " + factory + ")"
                } else {
                    ""
                }
                LOGGER.debug("BPM workflow step {} is implemented by {}{}",
                    ws.key, ws.value.class.canonicalName, factoryText
                )
            }
            if (!factoryExists)
                LOGGER.error("*** Factory {} referenced by {} does not exist! ***", factory, ws.value.class.canonicalName)
        }
    }

    override getBPMObjectFactoryForName(String name) {
        val factory = bpmObjectFactories.get(name)
        if (factory === null)
            throw new T9tBPMException(T9tBPMException.BPM_OBJECT_FACTORY_NOT_FOUND, name);
        return factory;
    }

    override getWorkflowStepForName(String name) {
        val step = workflowSteps.get(name)
        if (step === null)
            throw new T9tBPMException(T9tBPMException.BPM_STEP_NOT_FOUND, name);
        return step;
    }

    override getAllSteps() {
        return workflowSteps ?: ImmutableMap.of;  // this is save because the map is immutable
    }

    override getAllFactories() {
        return bpmObjectFactories ?: ImmutableMap.of;
    }
}
