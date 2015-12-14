# MagicHosts build file

NODE_BIN = "./node_modules/.bin/"
HOSTS_OUT_DIR = "./out/hosts/"

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

build-create-host-dirs:
	@for host_dir in $$(ls ./hosts/); do \
		if [ -d ./hosts/$$host_dir ]; then \
			mkdir ${HOSTS_OUT_DIR}$$host_dir -p; \
		fi; \
	done;

build-javascript: build-create-host-dirs
	@for host_dir in $$(ls ./hosts/); do \
		if [ -d ./hosts/$$host_dir/js/ ]; then \
			for js_lib in $$(ls ./hosts/$$host_dir/js); do \
				${NODE_BIN}browserify \
					./hosts/$$host_dir/js/$$js_lib/index.js \
					-o ${HOSTS_OUT_DIR}$$host_dir/js/$$js_lib.js \
					-t [ babelify --presets [ es2015 ] ] \
				; \
			done; \
		fi; \
	done;

	@echo "build-javascript finished"

build-nginx: build-create-host-dirs
	@echo "copy nginx config"; \
	mkdir -p ./out/nginx/sites-enabled/; \
	\
	cp ./nginx/nginx.conf ./out/nginx/nginx.conf \
	;

build-static: build-create-host-dirs build-nginx
	mkdir -p ./out/hosts
	@for host_dir in $$(ls ./hosts/); do \
		if [ -d ./hosts/$$host_dir/assets/ ]; then \
			echo "copy assets directory to ${HOSTS_OUT_DIR}$$host_dir" && \
			cp ./hosts/$$host_dir/assets/* ${HOSTS_OUT_DIR}$$host_dir/ -rf; \
		fi; \
		\
		echo "build nginx site config for $$host_dir" && \
		cp ./nginx/sites-enabled/default ./out/nginx/sites-enabled/$$host_dir && \
		sed -i -e s/HOSTNAME/$$host_dir/g ./out/nginx/sites-enabled/$$host_dir; \
	done;



# build html, css and js for every page in the hosts/ directory.
build-html: build-create-host-dirs
	@for host_dir in $$(ls ./hosts/); do \
		echo "processing folder ./hosts/$$host_dir/" && \
		if [ -d ./hosts/$$host_dir/html/pages ]; then \
			echo "create html files" && \
			mkdir ${HOSTS_OUT_DIR}$$host_dir -p && \
			${NODE_BIN}jade ./hosts/$$host_dir/html/pages/* --out ${HOSTS_OUT_DIR}$$host_dir/; \
		fi; \
	done;

build-css: build-create-host-dirs
	@for host_dir in $$(ls ./hosts/); do \
		if [ -d ./hosts/$$host_dir/css ]; then \
			echo "build stylus css" && \
			mkdir ${HOSTS_OUT_DIR}$$host_dir/css -p && \
			${NODE_BIN}stylus \
				./hosts/$$host_dir/css/main.styl \
				--out ${HOSTS_OUT_DIR}$$host_dir/css/ \
				--use nib; \
		fi; \
	done;

# build html, css and js for every page in the hosts/ directory.
build: ; ${MAKE} -j 6 \
				build-create-host-dirs \
				build-html \
				build-static \
				build-css \
				build-javascript;
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

watch-javascript:
	@echo "start watching javascript"
	@while inotifywait -r \
		-e close_write ./hosts/**/js/; do make build-javascript; \
	done;

watch-static:
	@echo "start watching static files"
	@while inotifywait -r \
		-e close_write ./hosts/**/assets/; do make build-static; \
	done;

watch-css:
	@echo "start watching css"
	@while inotifywait -r \
		-e close_write ./hosts/**/css/; do make build-css; \
	done;

watch-html:
	@echo "start watching html"
	@while inotifywait -r \
		-e close_write ./hosts/**/html/; do make build-html; \
	done;

watch: ; @${MAKE} -j4 \
					watch-javascript \
					watch-static \
					watch-css \
					watch-html;

# server is the default task
all: server
