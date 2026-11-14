
package com.cap46.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "deployment_events")
public class DeploymentEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(length = 1000)
    private String description;

    @Column(name = "event_type", nullable = false)
    private String eventType;

    @Column(nullable = false)
    private String status;

    public DeploymentEvent() {
    }

    public DeploymentEvent(String eventType, String status,
                           String description) {
        this.eventType = eventType;
        this.status = status;
        this.description = description;
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public String getDescription() {
        return description;
    }

    public String getEventType() {
        return eventType;
    }

    public String getStatus() {
        return status;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public void setEventType(String eventType) {
        this.eventType = eventType;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}
