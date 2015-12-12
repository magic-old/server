# MagicHosts build file

NODE_BIN = ./node_modules/.bin/

# remove dist files
clean:
	rm out -rf

# install npm dependencies
install:
	npm install;
	git clone git@github.com:jaeh/jaeh.at ./hosts/jaeh.at || echo "host jaeh.at already exists";
	git clone git@github.com:wizardsatwork/wizardsat.work ./hosts/wizardsat.work || echo "host wizardsat.work already exists";
	@echo "Install finished"

uninstall: clean
	rm node_modules -r;

# build html, css and js for every page in the hosts/ directory.
build:
	rm ./out -rf && mkdir out
	@echo "copy nginx config"
	mkdir -p ./out/nginx/sites-enabled

	cp ./nginx/nginx.conf ./out/nginx/nginx.conf
	@for host_dir in $$(ls ./hosts/); do \
		echo "processing folder ./hosts/$$host_dir/" && \
		if [ -d ./hosts/$$host_dir/html/pages ]; then \
			echo "create html files" && \
			mkdir ./out/hosts/$$host_dir -p && \
			${NODE_BIN}jade ./hosts/$$host_dir/html/pages/* --out ./out/hosts/$$host_dir/; \
		fi && \
		\
		if [ -d ./hosts/$$host_dir/css ]; then \
			echo "build stylus css" && \
			mkdir ./out/hosts/$$host_dir/css -p && \
			${NODE_BIN}stylus ./hosts/$$host_dir/css/main.styl --out ./out/hosts/$$host_dir/css/; \
		fi && \
		\
		if [ -d ./hosts/$$host_dir/js ]; then \
			echo "browserify javascript" && \
			mkdir ./out/hosts/$$host_dir/js -p; \
			${NODE_BIN}browserify \
				./hosts/$$host_dir/js/index.js \
				-t [ babelify --presets [ es2015 ] ] \
				> ./out/hosts/$$host_dir/js/index.js; \
		fi; \
		\
		if [ -d ./hosts/$$host_dir/assets/ ]; then \
			echo "copy assets directory to ./out/$$host_dir" && \
			cp ./hosts/$$host_dir/assets/* ./out/hosts/$$host_dir/ -rf; \
		fi; \
		\
		echo "build nginx site config for $$host_dir" && \
		cp ./nginx/sites-enabled/default ./out/nginx/sites-enabled/$$host_dir && \
		sed -i -e s/HOSTNAME/$$host_dir/g ./out/nginx/sites-enabled/$$host_dir; \
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

watch:
	while inotifywait -r \
		-e close_write ./*; do make build; \
	done;

# server is the default task
all: server
