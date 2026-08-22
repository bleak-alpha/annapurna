FROM openjdk:17-jdk-slim

# Install curl and wait utilities
RUN apt-get update && apt-get install -y \
    curl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the jar file
COPY target/annapurna-backend-1.0.0.jar app.jar

# Create a startup script
RUN echo '#!/bin/bash\n\
echo "Waiting for database..."\n\
while ! nc -z database 5432; do\n\
  sleep 1\n\
done\n\
echo "Database is ready!"\n\
exec java $JAVA_OPTS -jar app.jar' > /app/start.sh

RUN chmod +x /app/start.sh

EXPOSE 8080

# Use the startup script
ENTRYPOINT ["/app/start.sh"]