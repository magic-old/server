# MagicHosts build file

NODE_BIN = "./node_modules/.bin/"
HOSTS_OUT_DIR = "./out/hosts/"
HOSTS_DIR = "./hosts/"
LETSENCRYPT_DIR = "./.bin/letsencrypt/"
LETSENCRYPT_SH = "${LETSENCRYPT_DIR}letsencrypt.sh"
LETSENCRYPT_KEY = "./.bin/letsencrypt.key"

# default task
all: build docker-build docker-run

# remove dist files
clean:
	rm out -rf;

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
		dir=${HOSTS_OUT_DIR}$$host_dir; \
		echo "creating directory $$dir"; \
		mkdir $$dir -p; \
	done;

build-javascript: build-create-host-dirs
	@for host_dir in $$(ls ${HOSTS_DIR}); do \
		dir=${HOSTS_DIR}$$host_dir/js; \
		if [ -d $$dir/ ]; then \
			for lib in $$(ls $$dir/); do \
				lib_dir=$$dir/$$lib; \
				out_dir=${HOSTS_OUT_DIR}$$host_dir/js; \
				echo "test lib_dir $$lib_dir"; \
				if [ -d $$lib_dir ]; then \
					lib_file=$$lib_dir/index.js; \
					if [ -f $$lib_file ]; then \
						mkdir -p $$out_dir; \
						out_file=$$out_dir/$$lib.js; \
						echo "build javascript lib $$out_file"; \
						${NODE_BIN}browserify \
							$$lib_file \
							-o $$out_file \
							-t [ babelify --presets [ es2015 ] ] \
						; \
					else \
						for sub_lib in $$(ls $$lib_dir); do \
							if [ -d $$lib_dir ]; then \
								sub_lib_dir=$$lib_dir/$$sub_lib; \
								if [ -f $$sub_lib_dir/index.js ]; then \
									lib_out_dir=$$out_dir/$$lib/$$sub_lib; \
									mkdir -p $$out_dir/$$lib; \
									echo "make dir $$out_dir/$$lib"; \
									echo "build javascript lib $$sub_lib_dir.js to $$lib_out_dir.js"; \
									${NODE_BIN}browserify \
										$$sub_lib_dir/index.js \
										-o $$lib_out_dir.js \
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
		js_dir=${HOSTS_DIR}$$host_dir/js; \
		if [ -d $$js_dir ]; then \
			for js_lib in $$(ls $$js_dir); do \
				lib_dir=$$js_dir/$$js_lib; \
				if [ -d $$lib_dir ]; then \
					if [ -f $$lib_dir/index.js ]; then \
						mkdir -p $$js_dir; \
						echo "watch javascript lib $$lib_dir.js"; \
						(${NODE_BIN}watchify \
							$$lib_dir/index.js \
							-o $$lib_dir.js \
							-t [ babelify --presets [ es2015 ] ] \
						&); \
					else \
						for sub_lib in $$(ls $$lib_dir); do \
							sub_dir=$$lib_dir/$$sub_lib; \
							if [ -d $$lib_dir ]; then \
								if [ -f $$sub_dir/index.js ]; then \
									mkdir -p $$lib_dir; \
									echo "watch javascript lib $$sub_dir.js"; \
									(${NODE_BIN}watchify \
										$$sub_dir/index.js \
										-o $$sub_dir.js \
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

	@echo "watch-javascript started. stop with 'make watch-stop'"

build-nginx: build-create-host-dirs
	@echo "copy nginx config";
	@mkdir -p ./out/nginx/sites-enabled/;
	@cp ./nginx/nginx.conf ./out/nginx/nginx.conf;
	@cp ./nginx/mime.types ./out/nginx/mime.types;
	@for host_dir in $$(ls ${HOSTS_DIR}); do \
		nginx_out_dir=./out/nginx/sites-enabled/$$host_dir; \
		echo "build nginx site config for $$host_dir"; \
		cp ./nginx/sites-enabled/default $$nginx_out_dir; \
		host_names=$$(cat ./hosts/$$host_dir/HOSTNAMES); \
		account_thumbprint=$$(${LETSENCRYPT_SH} thumbprint -a ${LETSENCRYPT_KEY}); \
		echo "host $$host"; \
		echo $$account_thumbprint; \
		sed -i \
			-e s/ROOT_DIR/"$$host_dir"/g \
			-e s/HOSTNAME/"$$host_names"/g \
			-e s/ACCOUNT_THUMBPRINT/"$$account_thumbprint"/g \
			-e s/"account thumbprint: "/""/g \
			$$nginx_out_dir \
		; \
	done;

build-static: build-create-host-dirs build-nginx
	mkdir -p ${HOSTS_OUT_DIR}
	@for host_dir in $$(ls ${HOSTS_DIR}); do \
		asset_dir=${HOSTS_DIR}$$host_dir/assets/; \
		if [ -d $$asset_dir ]; then \
			echo "copy assets directory to ${HOSTS_OUT_DIR}$$host_dir" && \
			cp $$asset_dir/* ${HOSTS_OUT_DIR}$$host_dir/ -rf; \
		fi; \
	done; \

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
build: ; ${MAKE} -j 4 \
				build-create-host-dirs \
				build-html \
				build-static \
				build-css \
				build-javascript \
				;
	@echo "Build finished";

# build the docker container
docker-build:
	docker build -t magic-host .

# run the dockerfile on port 80:80,
# --rm removes the container on exit
docker-run: docker-rm
	docker run \
	--name magic-server \
	 -p 80:80 \
	 -i -t \
	 --rm \
	 -v $(PWD)/out/hosts:/www/data \
	magic-host \
	;

docker-rm:
	echo 'deleting container'
	@docker rm -f magic-server || echo 'container does not exist'

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

watch-javascript: watch-js;

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

watch: build
	@${MAKE} -j4 \
		watch-javascript \
		watch-static \
		watch-css \
		watch-html;

watch-stop:
	pkill -f ./node_modules/.bin/watchify

git-check-hosts:
	@for host_dir in $$(ls ./hosts/); do \
		echo "checking host ./hosts/$$host_dir"; \
		cd ./hosts/$$host_dir/ && \
		git status && \
		cd ../../; \
	done;

letsencrypt-install:
	@git clone https://github.com/magic/letsencrypt.sh ${LETSENCRYPT_DIR};

letsencrypt-key:
	@mkdir -p ${LETSENCRYPT_DIR};
	@openssl genrsa -out ${LETSENCRYPT_KEY} 4096
	@echo "generated letsencrypt-key"

letsencrypt-register:
	${LETSENCRYPT_SH} register -a ${LETSENCRYPT_KEY} -e jascha@jaeh.at

letsencrypt-generate-nginx-config:
	@mkdir -p ${LETSENCRYPT_DIR};
	@echo $$(${LETSENCRYPT_SH} thumbprint -a ${LETSENCRYPT_KEY});

