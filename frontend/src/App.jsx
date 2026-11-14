
import { useCallback, useEffect, useState } from "react";
import "./App.css";

const API = {
  health: "/api/health",
  info: "/api/info",
  events: "/api/deployment-events",
  actuator: "/actuator/health",
};

function StatusBadge({ status }) {
  const normalized = String(status || "UNKNOWN").toUpperCase();

  const className =
    normalized === "UP" ||
    normalized === "RUNNING" ||
    normalized === "SUCCESS"
      ? "status-badge"
      : normalized === "UNKNOWN"
        ? "status-badge warning"
        : "status-badge down";

  return <span className={className}>{normalized}</span>;
}

function App() {
  const [backendStatus, setBackendStatus] = useState("CHECKING");
  const [databaseStatus, setDatabaseStatus] = useState("CHECKING");
  const [nginxStatus,] = useState("RUNNING");

  const [applicationInfo, setApplicationInfo] = useState(null);
  const [deploymentEvents, setDeploymentEvents] = useState([]);

  const [lastUpdated, setLastUpdated] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const fetchDashboardData = useCallback(async () => {
    setLoading(true);

    try {
      const [healthResult, infoResult, eventsResult, actuatorResult] =
        await Promise.allSettled([
          fetch(API.health),
          fetch(API.info),
          fetch(API.events),
          fetch(API.actuator),
        ]);

      // Backend health
      if (
        healthResult.status === "fulfilled" &&
        healthResult.value.ok
      ) {
        const health = await healthResult.value.json();

        setBackendStatus(
          String(health.status || "UP").toUpperCase()
        );
      } else {
        setBackendStatus("DOWN");
      }

      // Application information
      if (
        infoResult.status === "fulfilled" &&
        infoResult.value.ok
      ) {
        const info = await infoResult.value.json();
        setApplicationInfo(info);
      }

      // Deployment events
      if (
        eventsResult.status === "fulfilled" &&
        eventsResult.value.ok
      ) {
        const events = await eventsResult.value.json();

        setDeploymentEvents(
          Array.isArray(events) ? events : []
        );
      }

      // Database health
      if (
        actuatorResult.status === "fulfilled" &&
        actuatorResult.value.ok
      ) {
        const actuator = await actuatorResult.value.json();

        setDatabaseStatus(
          String(
            actuator.components?.db?.status ||
            actuator.details?.db?.status ||
            "UNKNOWN"
          ).toUpperCase()
        );
      } else {
        setDatabaseStatus("UNKNOWN");
      }

      setError("");
      setLastUpdated(new Date());
    } catch (err) {
      console.error("Dashboard update failed:", err);
      setError("Unable to retrieve some dashboard information.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    let active = true;

    const loadDashboard = async () => {
      if (active) {
        await fetchDashboardData();
      }
    };

    const initialFetch = setTimeout(loadDashboard, 0);
    const interval = setInterval(loadDashboard, 5000);

    return () => {
      active = false;
      clearTimeout(initialFetch);
      clearInterval(interval);
    };
  }, [fetchDashboardData]);

  const formatDate = (dateValue) => {
    if (!dateValue) return "Not available";

    const date = new Date(dateValue);

    if (Number.isNaN(date.getTime())) {
      return String(dateValue);
    }

    return date.toLocaleString();
  };

  const getEventVersion = (event) =>
    event.version || event.eventType || "DEPLOYMENT";

  const getEventMessage = (event) =>
    event.message || event.description || "Deployment event";

  const getEventStatus = (event) =>
    String(event.status || "UNKNOWN").toUpperCase();

  return (
    <main className="dashboard">

      {/* HEADER */}
      <header className="header">
        <div>
          <h1>CAP-46 Operations</h1>
          <p>
            Reverse Proxy Failure Isolation &amp; Safe Configuration Rollout
          </p>
        </div>

        <div className="header-actions">
          <StatusBadge status={nginxStatus} />

          <button
            className="refresh-btn"
            onClick={fetchDashboardData}
            disabled={loading}
          >
            {loading ? "Refreshing..." : "↻ Refresh"}
          </button>
        </div>
      </header>

      {/* ERROR MESSAGE */}
      {error && (
        <div className="panel" style={{ marginBottom: "20px" }}>
          <p style={{ color: "#f87171" }}>{error}</p>
        </div>
      )}

      {/* SERVICE STATUS */}
      <section>
        <h2 className="section-title">Infrastructure Overview</h2>
        <p className="section-subtitle">
          Live status of CAP-46 application components
        </p>

        <div className="status-grid">

          <div className="status-card">
            <p className="card-label">Nginx Reverse Proxy</p>
            <h3 className="card-value">Port 80</h3>
            <StatusBadge status={nginxStatus} />
            <p className="card-description">
              Public entry point and API routing
            </p>
          </div>

          <div className="status-card">
            <p className="card-label">React Frontend</p>
            <h3 className="card-value">Static UI</h3>
            <StatusBadge status="RUNNING" />
            <p className="card-description">
              Production frontend served through Nginx
            </p>
          </div>

          <div className="status-card">
            <p className="card-label">Spring Boot Backend</p>
            <h3 className="card-value">Port 8080</h3>
            <StatusBadge status={backendStatus} />
            <p className="card-description">
              REST APIs and application services
            </p>
          </div>

          <div className="status-card">
            <p className="card-label">MySQL Database</p>
            <h3 className="card-value">Port 3306</h3>
            <StatusBadge status={databaseStatus} />
            <p className="card-description">
              Internal database connection
            </p>
          </div>

        </div>
      </section>

      {/* APPLICATION INFORMATION AND EVENTS */}
      <section className="content-grid">

        {/* APPLICATION INFORMATION */}
        <div className="panel">
          <h2>Application Information</h2>

          <div className="info-row">
            <span>Application</span>
            <span>
              {applicationInfo?.application || "CAP-46"}
            </span>
          </div>

          <div className="info-row">
            <span>Version</span>
            <span>
              {applicationInfo?.version || "1.0.0"}
            </span>
          </div>

          <div className="info-row">
            <span>Backend</span>
            <span>Spring Boot</span>
          </div>

          <div className="info-row">
            <span>Frontend</span>
            <span>React + Vite</span>
          </div>

          <div className="info-row">
            <span>Reverse Proxy</span>
            <span>Nginx</span>
          </div>

          <div className="info-row">
            <span>Database</span>
            <span>MySQL 8.4</span>
          </div>

          <div className="info-row">
            <span>Deployment Mode</span>
            <span>Docker Compose</span>
          </div>
        </div>

        {/* DEPLOYMENT EVENTS */}
        <div className="panel">
          <h2>Deployment Events</h2>

          {deploymentEvents.length === 0 ? (
            <p style={{ color: "#94a3b8", fontSize: "13px" }}>
              No deployment events available.
            </p>
          ) : (
            <div className="events-list">
              {deploymentEvents.map((event, index) => (
                <div
                  className="event-item"
                  key={event.id ?? index}
                >
                  <div className="event-indicator" />

                  <div className="event-content">
                    <h3>
                      {getEventVersion(event)}
                    </h3>

                    <p>
                      {getEventMessage(event)}
                    </p>

                    <div className="event-meta">
                      {getEventStatus(event)} ·{" "}
                      {formatDate(event.createdAt)}
                    </div>
                  </div>

                  <StatusBadge status={getEventStatus(event)} />
                </div>
              ))}
            </div>
          )}
        </div>

      </section>

      {/* SYSTEM INFORMATION */}
      <section className="panel" style={{ marginBottom: "25px" }}>
        <h2>System Architecture</h2>

        <div className="info-row">
          <span>External Access</span>
          <span>Browser → Nginx :80</span>
        </div>

        <div className="info-row">
          <span>Frontend Routing</span>
          <span>Nginx → React Static Files</span>
        </div>

        <div className="info-row">
          <span>Backend Routing</span>
          <span>Nginx → backend:8080</span>
        </div>

        <div className="info-row">
          <span>Database Routing</span>
          <span>Backend → mysql:3306</span>
        </div>

        <div className="info-row">
          <span>Failure Handling</span>
          <span>HTTP 503 + Automatic Rollback</span>
        </div>
      </section>

      {/* FOOTER */}
      <footer className="footer">
        <span>CAP-46 | Reverse Proxy Operations Dashboard</span>

        <span>
          Last Updated:{" "}
          {lastUpdated ? formatDate(lastUpdated) : "Waiting..."}
        </span>
      </footer>

    </main>
  );
}

export default App;
