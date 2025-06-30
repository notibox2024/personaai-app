package com.kienlongbank.personaai.portal.api.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api/secured")
public class SecuredController {

    @GetMapping("/user")
    public ResponseEntity<Map<String, Object>> userEndpoint() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        
        return ResponseEntity.ok(Map.of(
            "message", "Endpoint này yêu cầu authentication",
            "user", auth.getName(),
            "authorities", auth.getAuthorities(),
            "timestamp", LocalDateTime.now()
        ));
    }

    @GetMapping("/admin")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> adminEndpoint() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        
        return ResponseEntity.ok(Map.of(
            "message", "Endpoint này chỉ dành cho ADMIN",
            "user", auth.getName(),
            "authorities", auth.getAuthorities(),
            "timestamp", LocalDateTime.now()
        ));
    }

    @GetMapping("/info")
    public ResponseEntity<Map<String, Object>> securityInfo() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        
        return ResponseEntity.ok(Map.of(
            "authenticated", auth.isAuthenticated(),
            "principal", auth.getPrincipal(),
            "authorities", auth.getAuthorities(),
            "timestamp", LocalDateTime.now()
        ));
    }
} 