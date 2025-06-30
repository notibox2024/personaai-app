package com.kienlongbank.personaai.portal.core.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@Configuration
@ComponentScan(basePackages = {
    "com.kienlongbank.personaai.portal.core",
    "com.kienlongbank.personaai.portal.common"
})
@EnableJpaRepositories(basePackages = "com.kienlongbank.personaai.portal.core.repository")
@EnableJpaAuditing
public class CoreConfig {
} 