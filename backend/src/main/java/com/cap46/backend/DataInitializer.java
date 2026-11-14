
package com.cap46.backend;

import com.cap46.backend.entity.DeploymentEvent;
import com.cap46.backend.repository.DeploymentEventRepository;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class DataInitializer {

    @Bean
    CommandLineRunner initializeDeploymentEvents(
            DeploymentEventRepository repository) {

        return args -> {
            if (repository.count() == 0) {

                repository.saveAll(List.of(
                    new DeploymentEvent(
                        "v1.0",
                        "SUCCESS",
                        "Initial deployment completed"
                    ),
                    new DeploymentEvent(
                        "v1.1",
                        "SUCCESS",
                        "Backend API configuration updated"
                    ),
                    new DeploymentEvent(
                        "v1.2",
                        "SUCCESS",
                        "Frontend dashboard deployed"
                    )
                ));

                System.out.println(
                    "Sample deployment events inserted successfully!"
                );
            }
        };
    }
}
