.PHONY: all

all:
	# Run these to download the model files
	python3 -c "from stepcount import sslmodel; sslmodel.get_sslnet()"
	python3 -c "from stepcount.stepcount import load_model; load_model('non-existent-file.txt', 'ssl')"
