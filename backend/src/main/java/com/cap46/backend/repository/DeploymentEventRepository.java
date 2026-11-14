
package com.cap46.backend.repository;

import com.cap46.backend.entity.DeploymentEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface DeploymentEventRepository
        extends JpaRepository<DeploymentEvent, Long> {

    List<DeploymentEvent> findAllByOrderByCreatedAtDesc();
}
