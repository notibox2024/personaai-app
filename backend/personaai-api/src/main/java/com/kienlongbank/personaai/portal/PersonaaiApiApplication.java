package com.kienlongbank.personaai.portal;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan(basePackages = {
    "com.kienlongbank.personaai.portal.api",
    "com.kienlongbank.personaai.portal.core",
    "com.kienlongbank.personaai.portal.common"
})
public class PersonaaiApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(PersonaaiApiApplication.class, args);
    }
} 