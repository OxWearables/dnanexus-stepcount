# DNAnexus applet for the `stepcount` Python package

Scripts, configuration files, and instructions to build a DNAnexus applet wrapping the Python package `stepcount` (https://github.com/OxWearables/stepcount) for use on the DNAnexus platform.

## Prerequisites
- Python 3.8 or higher
- The DNAnexus `dx` toolkit: `pip install dxpy`

The following shows how to use Anaconda to satisfy the above prerequisites (you can use any Python environment manager):

1. Download & install [Miniconda](https://docs.conda.io/en/latest/miniconda.html) (light-weight version of Anaconda).
1. (Windows) Once installed, launch the **Anaconda Prompt**.
1. Create a virtual environment:
    ```console
    conda create -n dxpy python=3.9 pip
    ```
    This creates a virtual environment called `dxpy` with Python version 3.9 and Pip.
1. Activate the environment:
    ```console
    conda activate dxpy
    ```
    You should now see `(dxpy)` written in front of your prompt.
1. Install `dxpy`:
    ```console
    pip install dxpy
    ```

You are all set! You have created an environment called `dxpy`, containing the DNAnexus package `dxpy`.
The next time that you want to use `dxpy`, open the Anaconda Prompt and activate the environment (step 4: `conda activate dxpy`). If you see `(dxpy)` in front of your prompt, you are ready to go!

Read the DNAnexus Quickstart to learn the core "`dx`" commands: https://documentation.dnanexus.com/getting-started/cli-quickstart. TL;DR:
- Use `dx login` to login to your DNAnexus account (username and password are the same as with the web browser).
- Most DNAnexus commands are basically Unix commands prefixed with "`dx`". For example:
    - `dx ls` to list files
    - `dx cd` to navigate folders
    - `dx mkdir` to create new folders
    - `dx rm` to remove files
    - `dx mv` to move/rename files
    - ...

## Building the applet

1. Clone this repository:
    ```console
    git clone https://github.com/OxWearables/dnanexus-stepcount.git
    ```
1. Navigate to cloned folder:
    ```console
    cd dnanexus-stepcount/
    ```
1. Build the asset required by the applet:
    ```console
    dx build_asset stepcount-asset
    ```
    Note: This might take 10-15 minutes!
    
    When the build finishes, it will display an *asset ID* at the end (something like `record-Gx3Z650JyBV1f4p5fV7Xp4ZQ`). **Copy this ID**. If you missed it, you can re-read it using `dx describe stepcount-asset`.
1. Open the file **stepcount/dxapp.json** and search for the field `"assetDepends"`:
    ```json
    "assetDepends": [
      {
        "id": "record-..."
      }
    ]
    ```
    Replace `"record-..."` with the ID you copied from the previous step. Save and exit.
1. Finally, build the applet:
    ```
    dx build stepcount
    ```

## Running the applet

To begin, download a sample accelerometer file:

https://wearables-files.ndph.ox.ac.uk/files/data/samples/ax3/tiny-sample.cwa.gz

and upload it to your DNAnexus project: `dx upload tiny-sample.cwa.gz`

Now you can run `stepcount` on the uploaded sample file:

```console
dx run stepcount -iinput_file=tiny-sample.cwa.gz
```
Note: This might take 5-10 minutes!

After the run finishes, you should see an "outputs/" folder in your DNAnexus project. You can check with `dx tree outputs/` which should look like this:

```console
outputs/
└── tiny-sample
    ├── tiny-sample-Bouts.csv.gz
    ├── tiny-sample-Daily.csv.gz
    ├── tiny-sample-DailyAdjusted.csv.gz
    ├── tiny-sample-Hourly.csv.gz
    ├── tiny-sample-HourlyAdjusted.csv.gz
    ├── tiny-sample-Info.json
    ├── tiny-sample-Minutely.csv.gz
    ├── tiny-sample-MinutelyAdjusted.csv.gz
    ├── tiny-sample-Steps.csv.gz
    ├── tiny-sample-Steps.png
    └── tiny-sample-StepTimes.csv.gz
```

## Troubleshooting

- Error: ('destination project is in region aws:xx-xxxx-x but "regionalOptions" do not contain this region. Please, update your "regionalOptions" specification',)
    - Solution: Open **stepcount/dxapp.json** and search for the `"regionalOptions"` field:
        ```json
        "regionalOptions": {
            "aws:eu-west-2": {
                ...
            }
        }
        ```
        Change `"aws:eu-west-2"` to your project region as indicated in your error message.
