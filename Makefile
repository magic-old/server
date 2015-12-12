# MagicHosts build file

NODE_BIN = ./node_modules/.bin/

# remove dist files
clean:
	rm out -rf

# install npm dependencies
install:
	npm install;
	@echo "Install finished"

uninstall: clean
	rm node_modules -r;

# build html, css and js for every page in the hosts/ directory.
build:
	rm ./out -rf && mkdir out
	@echo "copy nginx config"
	mkdir -p ./out/nginx/sites-enabled

	cp ./nginx/nginx.conf ./out/nginx/nginx.conf
	@for a in $$(ls ./hosts/); do \
		echo "processing folder ./hosts/$$a/" && \
		if [ -d ./hosts/$$a/html/pages ]; then \
			echo "create html files" && \
			mkdir ./out/$$a -p && \
			${NODE_BIN}jade ./hosts/$$a/html/pages/* --out ./out/hosts/$$a/; \
		fi && \
		\
		if [ -d ./hosts/$$a/css ]; then \
			echo "build stylus css" && \
			mkdir ./out/hosts/$$a/css -p && \
			${NODE_BIN}stylus ./hosts/$$a/css/main.styl --out ./out/hosts/$$a/css/; \
		fi && \
		\
		if [ -d ./hosts/$$a/js ]; then \
			echo "browserify javascript" && \
			mkdir ./out/hosts/$$a/js -p && \
			${NODE_BIN}browserify \
			./hosts/$$a/js/index.js \
			 -t [ babelify --presets [ es2015 ] ] \
			--out ./out/hosts/$$a/css/; \
		fi; \
		\
		if [ -d ./hosts/$$a/assets/ ]; then \
			echo "copy assets directory to ./out/$$a" && \
			cp ./hosts/$$a/assets/* ./out/hosts/$$a/ -rf; \
		fi; \
		\
		echo "build nginx site config for $$a" && \
		cp ./nginx/sites-enabled/default ./out/nginx/sites-enabled/$$a && \
		sed -i -e s/HOSTNAME/$$a/g ./out/nginx/sites-enabled/$$a; \
	done;
	@echo "Build finished"

# build the docker container
docker-build:
	docker build -t magic-host .

# run the dockerfile on port 80:80,
# --rm removes the container on exit
docker-run:
	docker run \
	--name magic-server \
	 -p 80:80 \
	 -i -t \
	 --rm \
	 -v $(PWD)/out/hosts:/www/data \
	magic-host \
	;

# removes ALL docker containers
rmContainers:
	containers=$(shell docker ps -a -q)
ifneq (${containers}"t","t")
	@echo "removing containers ${containers}" && \
	docker rm ${containers}
endif

# removes ALL docker images
rmImages:
	docker rmi $(shell docker images -q)

# main docker task, builds deps then runs the container
docker: build docker-build docker-run

# server is the default task
all: server
