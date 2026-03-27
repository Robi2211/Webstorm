FROM alpine:3.16.2

COPY ./bin/todo-app /app/todo-app
COPY ./public /app/public
RUN chmod +x /app/todo-app
WORKDIR /app
CMD ["./todo-app"]
EXPOSE 3000
