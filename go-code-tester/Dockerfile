FROM golang:1.24

LABEL "com.github.actions.name"="go-code-tester"
LABEL "com.github.actions.description"="Runs unit tests and verifies code coverage per package"
LABEL "com.github.actions.icon"="eye"
LABEL "com.github.actions.color"="gray-dark"

LABEL version="1.0.0"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
