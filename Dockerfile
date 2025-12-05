# Use an official Elixir image as a parent image (Alpine = lightweight)
FROM elixir:1.14-alpine

# Install build dependencies
# inotify-tools is required for Phoenix live reload
# postgresql-client for DB access
RUN apk add --no-cache \
    postgresql-client \
    inotify-tools \
    build-base \
    git

# Create app directory and copy the Elixir projects into it
RUN mkdir /app
WORKDIR /app

# Install hex package manager
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy the parent host's current directory contents into the container at /app
COPY . /app

# Install dependencies
RUN mix deps.get

# Compile the project
RUN mix do compile

# Expose port 4000
EXPOSE 4000

# Command to run the server
CMD ["mix", "phx.server"]
