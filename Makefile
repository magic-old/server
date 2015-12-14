# MagicHosts build file

NODE_BIN = "./node_modules/.bin/"
HOSTS_OUT_DIR = "./out/hosts/"
HOSTS_DIR = "./hosts/"

# remove dist files
clean:
	rm out -rf

# install npm dependencies
install:
	npm install;
	host=wizardsat.work
	#git clone git@github.com:wizardsatwork/$$host \
	#	${HOSTS_DIR}$$host \
	# || echo "host $$host already exists";
	@echo "Install finished"

uninstall: clean
	rm node_modules -r;

build-create-host-dirs:
	@for host_dir in $$(ls ${HOSTS_DIR}); do \
		dir=${HOSTS_DIR}$$host_dir; \
		echo "creating directory $$dir"; \
		if [ -d $$dir ]; then \
			mkdir $$dir -p; \
		fi; \
	done;

build-javascript: build-create-host-dirs
	@for host_dir in $$(ls ${HOSTS_DIR}); do \
		js_dir=${HOSTS_DIR}$$host_dir/js; \
		if [ -d $$js_dir/ ]; then \
			for js_lib in $$(ls $$js_dir/); do \
				lib_dir=$$js_dir/$$js_lib; \
				out_dir=${HOSTS_OUT_DIR}$$host_dir/js; \
				echo "out_dir $$out_dir"; \
				if [ -d $$lib_dir ]; then \
					echo "lib_dir $$lib_dir"; \
					lib_file=$$lib_dir/index.js; \
					echo "lib_file $$lib_file"; \
					if [ -f $$lib_file ]; then \
						mkdir -p $$out_dir; \
						out_file=$$out_dir/$$js_lib.js; \
						echo "build javascript lib $$out_file"; \
						${NODE_BIN}browserify \
							$$lib_file \
							-o $$out_file \
							-t [ babelify --presets [ es2015 ] ] \
						; \
					else \
						for js_sub_lib in $$(ls $$lib_dir); do \
							if [ -d $$lib_dir ]; then \
								sub_lib_dir=$$lib_dir/$$js_sub_lib; \
								if [ -f $$js_sub_dir/index.js ]; then \
									mkdir -p $$lib_dir; \
									echo "build javascript lib $$sub_lib_dir.js"; \
									${NODE_BIN}browserify \
										$$sub_lib-dir/index.js \
										-o $$sub_lib_dir.js \
										-t [ babelify --presets [ es2015 ] ] \
									; \
								fi; \
							fi; \
						done; \
					fi; \
				fi; \
			done; \
		fi; \
	done;
	@echo "build-javascript finished"



watch-js: build-create-host-dirs
	@for host_dir in $$(ls ${HOSTS_DIR}); do \
		if [ -d ${HOSTS_DIR}$$host_dir/js/ ]; then \
			for js_lib in $$(ls ${HOSTS_DIR}$$host_dir/js); do \
				if [ -d ${HOSTS_DIR}$$host_dir/js/$$js_lib ]; then \
					if [ -f ${HOSTS_DIR}$$host_dir/js/$$js_lib/index.js ]; then \
						mkdir -p ${HOSTS_OUT_DIR}$$host_dir/js/; \
						echo "watch javascript lib ${HOSTS_OUT_DIR}$$host_dir/js/$$js_lib.js"; \
						(${NODE_BIN}watchify \
							${HOSTS_DIR}$$host_dir/js/$$js_lib/index.js \
							-o ${HOSTS_OUT_DIR}$$host_dir/js/$$js_lib.js \
							-t [ babelify --presets [ es2015 ] ] \
						&); \
					else \
						for js_sub_lib in $$(ls ${HOSTS_DIR}$$host_dir/js/$$js_lib/); do \
							if [ -d ${HOSTS_DIR}$$host_dir/js/$$js_lib ]; then \
								if [ -f ${HOSTS_DIR}$$host_dir/js/$$js_lib/$$js_sub_lib/index.js ]; then \
									mkdir -p ${HOSTS_OUT_DIR}$$host_dir/js/$$js_lib/; \
									echo "watch javascript lib ${HOSTS_OUT_DIR}$$host_dir/js/$$js_lib/$$js_sub_lib.js"; \
									(${NODE_BIN}watchify \
										${HOSTS_DIR}$$host_dir/js/$$js_lib/$$js_sub_lib/index.js \
										-o ${HOSTS_OUT_DIR}$$host_dir/js/$$js_lib/$$js_sub_lib.js \
										-t [ babelify --presets [ es2015 ] ] \
									&); \
								fi; \
							fi; \
						done; \
					fi; \
				fi; \
			done; \
		fi; \
	done;

	@echo "watch-javascript ended"

build-nginx: build-create-host-dirs
	@echo "copy nginx config"; \
	mkdir -p ./out/nginx/sites-enabled/; \
	\
	cp ./nginx/nginx.conf ./out/nginx/nginx.conf \
	;

build-static: build-create-host-dirs build-nginx
	mkdir -p ./out/hosts
	@for host_dir in $$(ls ${HOSTS_DIR}); do \
		if [ -d ${HOSTS_DIR}$$host_dir/assets/ ]; then \
			echo "copy assets directory to ${HOSTS_OUT_DIR}$$host_dir" && \
			cp ${HOSTS_DIR}$$host_dir/assets/* ${HOSTS_OUT_DIR}$$host_dir/ -rf; \
		fi; \
		\
		echo "build nginx site config for $$host_dir" && \
		cp ./nginx/sites-enabled/default ./out/nginx/sites-enabled/$$host_dir && \
		sed -i -e s/HOSTNAME/$$host_dir/g ./out/nginx/sites-enabled/$$host_dir; \
	done;

# build html, css and js for every page in the hosts/ directory.
build-html: build-create-host-dirs
	@for host_dir in $$(ls ${HOSTS_DIR}); do \
		echo "processing folder ${HOSTS_DIR}$$host_dir/" && \
		if [ -d ${HOSTS_DIR}$$host_dir/html/pages ]; then \
			echo "create html files" && \
			mkdir ${HOSTS_OUT_DIR}$$host_dir -p && \
			for jade_dir in $$(ls ${HOSTS_DIR}$$host_dir/html/pages); do \
				if [ -d ${HOSTS_DIR}$$host_dir/html/pages/$$jade_dir ]; then \
					${NODE_BIN}jade \
						${HOSTS_DIR}$$host_dir/html/pages/$$jade_dir/* \
					--hierarchy \
					--out ${HOSTS_OUT_DIR}$$host_dir/$$jade_dir; \
				fi; \
				if [ -f ${HOSTS_DIR}$$host_dir/html/pages/$$jade_dir ]; then \
					${NODE_BIN}jade \
						${HOSTS_DIR}$$host_dir/html/pages/$$jade_dir \
					--hierarchy \
					--out ${HOSTS_OUT_DIR}$$host_dir/; \
				fi; \
			done; \
		fi; \
	done;

build-css: build-create-host-dirs
	@for host_dir in $$(ls ${HOSTS_DIR}); do \
		if [ -d ${HOSTS_DIR}$$host_dir/css ]; then \
			echo "build stylus css" && \
			mkdir ${HOSTS_OUT_DIR}$$host_dir/css -p && \
			${NODE_BIN}stylus \
				${HOSTS_DIR}$$host_dir/css/main.styl \
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

watch-javascript: ; @${MAKE} -j 10 watch-js;

watch-static:
	@echo "start watching static files"
	@while inotifywait -r \
		-e close_write ${HOSTS_DIR}**/assets/; do make build-static; \
	done;

watch-css:
	@echo "start watching css"
	@while inotifywait -r \
		-e close_write ${HOSTS_DIR}**/css/; do make build-css; \
	done;

watch-html:
	@echo "start watching html"
	@while inotifywait -r \
		-e close_write ${HOSTS_DIR}**/html/; do make build-html; \
	done;

watch: ; @${MAKE} -j4 \
					watch-javascript \
					watch-static \
					watch-css \
					watch-html;

watch-stop:
	pkill -f ./node_modules/.bin/watchify
# server is the default task
all: server
