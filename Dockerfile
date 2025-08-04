#FROM node:20-alpine as build

#WORKDIR /app

#COPY package*.json ./
#RUN npm install

#COPY . .
#RUN npm run build

# Production image s nginx
#FROM nginx:alpine

# Skopíruj build výstup do nginx html
#COPY --from=build /app/dist /usr/share/nginx/html

# Skopíruj tvoje template JSONy
#COPY ./public/templates /usr/share/nginx/html/templates

# Voliteľne: vlastný nginx.conf ak treba
# COPY ./nginx.conf /etc/nginx/nginx.conf




FROM node:20-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci

COPY . .

RUN npm run sv-check && npm run build

FROM nginx:1.27-alpine AS server

COPY --from=builder /app/dist/ /usr/share/nginx/html/

RUN chmod -R o+r /usr/share/nginx/html

RUN find /usr/share/nginx/html -type d -exec chmod o+rx {} \; && \
    find /usr/share/nginx/html -type f -exec chmod o+r {} \;

EXPOSE 80
