import pathlib
from stepcount import stepcount, sslmodel

# torch hub load
sslmodel.get_sslnet()
# download SSL weights
model_path = pathlib.Path(stepcount.__file__).parent / f"{stepcount.__model_version__['ssl']}.joblib.lzma"
stepcount.load_model(model_path, 'ssl')
# download RF weights
model_path = pathlib.Path(stepcount.__file__).parent / f"{stepcount.__model_version__['rf']}.joblib.lzma"
stepcount.load_model(model_path, 'rf')
