package com.arvatosystems.t9t.base.jpa.jta.impl;

import java.util.Set;

import javax.persistence.Entity;
import javax.persistence.MappedSuperclass;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.arvatosystems.t9t.cfg.be.T9tServerConfiguration;
import com.arvatosystems.t9t.init.InitContainers;

import de.jpaw.bonaparte.jpa.refs.PersistenceProviderJPA;
import de.jpaw.dp.Jdp;
import de.jpaw.dp.Startup;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

@Startup(12000)
public class InitJpa {

    private static final Logger LOGGER = LoggerFactory.getLogger(InitJpa.class);

    @PersistenceContext(unitName = "t9t-DS")
    public static EntityManager presetEntityManager;  // HAS TO be defined in scenarios inside a Java EE server

    public static void onStartup() {
        T9tServerConfiguration cfg = Jdp.getRequired(T9tServerConfiguration.class);
        LOGGER.info("Binding preset JPA EM for PU name {}", cfg.persistenceUnitName);
        Jdp.bindInstanceTo(presetEntityManager, EntityManager.class);
        Jdp.registerWithCustomProvider(PersistenceProviderJPA.class, new PersistenceProviderJPAProvider(presetEntityManager));
        // next lines are just for user info
        final Set<Class<?>> mcl = InitContainers.getClassesAnnotatedWith(MappedSuperclass.class);
        for (Class<?> e : mcl)
            LOGGER.info("Found mapped Superclass class {}", e.getCanonicalName());

        final Set<Class<?>> entities = InitContainers.getClassesAnnotatedWith(Entity.class);
        for (Class<?> e : entities)
            LOGGER.info("Found entity class {}", e.getCanonicalName());
    }
}
