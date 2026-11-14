
package com.cap46.backend.controller;

import com.cap46.backend.repository.DeploymentEventRepository;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
public class DeploymentController {

    private final DeploymentEventRepository repository;

    public DeploymentController(DeploymentEventRepository repository) {
        this.repository = repository;
    }

    @GetMapping("/api/deployment-events")
    public List<Map<String, Object>> getDeploymentEvents() {

        return repository.findAllByOrderByCreatedAtDesc()
                .stream()
                .map(event -> Map.<String, Object>of(
                        "id", event.getId(),
                        "version", event.getEventType(),
                        "status", event.getStatus(),
                        "message", event.getDescription(),
                        "createdAt", event.getCreatedAt()
                ))
                .toList();
    }
}
