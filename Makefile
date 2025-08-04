up: 
	docker compose up -d
down:
	docker compose down
build:
	docker compose up --build
enter:
	docker exec -it niimblue sh
ophrans:
	docker compose down --volumes --remove-orphans
