# DNAnexus applet for the `stepcount` Python package

Scripts, configuration files, and instructions to create a DNAnexus applet for the Python package `stepcount` (https://github.com/OxWearables/stepcount) for use on the DNAnexus platform.

## Prerequisites
- Python 3.8 or higher
- The DNAnexus `dx` toolkit: `pip install dxpy`
- git

The following shows how to use Anaconda to satisfy the above prerequisites (you can use any Python environment manager):

1. Download & install [Miniconda](https://docs.conda.io/en/latest/miniconda.html) (light-weight version of Anaconda).
1. (Windows) Once installed, launch the **Anaconda Prompt**.
1. Create a virtual environment:
    ```console
    conda create -n dxpy python=3.9 pip git
    ```
    This creates a virtual environment named `dxpy` with Python version 3.9 and Pip.
1. Activate the environment:
    ```console
    conda activate dxpy
    ```
    You should now see `(dxpy)` written in front of your prompt.
1. Install `dxpy`:
    ```console
    pip install dxpy
    ```

You are all set! You have created an environment named `dxpy`, containing the DNAnexus package `dxpy`.
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
    > Note: This might take 10-15 minutes! This process might show a bunch of warnings - just ignore them for now.
    
    When the build finishes, it will display an *asset ID* at the end (something like `record-Gx3Z650JyBV1f4p5fV7Xp4ZQ`). **Copy this ID**. If you missed it, you can re-read it using `dx describe stepcount-asset`.
1. Open the file **stepcount/dxapp.json** and search for the field `"assetDepends"`:
    ```text
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

## Versioning

To ensure reproducibility and follow best practices, we recommend explicitly pinning the version of the `stepcount` package in your asset. You can browse [the `stepcount` releases on GitHub](https://github.com/OxWearables/stepcount/releases) to find all available versions.

To pin a version:

1. Open the `stepcount-asset/dxasset.json` file.
2. Edit the `"execDepends"` section to include the desired version of `stepcount`. For example, to pin the version to 3.12.0, you would specify:

    ```text
    "execDepends": [
      {"name": "stepcount", "version": "3.12.0", "package_manager": "pip"},
      {...},
    ]
    ```
3. Save and close the file.
4. Rebuild the asset by running:
    
    ```bash
    dx build_asset stepcount-asset
    ```

By pinning the version, you ensure consistent behavior across different environments and over time.

## Troubleshooting

- Error: ('destination project is in region aws:xx-xxxx-x but "regionalOptions" do not contain this region. Please, update your "regionalOptions" specification',)
    - Solution: Open **stepcount/dxapp.json** and search for the `"regionalOptions"` field:
        ```text
        "regionalOptions": {
            "aws:eu-west-2": {...}
        }
        ```
        Change `"aws:eu-west-2"` to your project region as indicated in your error message.

## Additional Guides

### Processing multiple files

The most straightforward approach to process multiple files is to run a separate `dx run` command for each file. Below, we demonstrate how to do this programmatically using basic Unix shell commands (it should also work in Windows Anaconda Prompt).

The first step is to generate a list of file paths you want to process. In this example, we use accelerometer data files from the UK Biobank (approximately 100,000 files). We leverage the `dx find data` command, filtered by the field ID for accelerometer data (`90001`), and use `awk` to extract just the file paths:

```console
dx find data --property field_id=90001 | awk '{print $6}' > my-files.txt
```

The resulting `my-files.txt` file should contain entries like:
```text
/Bulk/Activity/Raw/54/5408734_90001_1_0.cwa
/Bulk/Activity/Raw/49/4945583_90001_1_0.cwa
/Bulk/Activity/Raw/20/2066665_90001_1_0.cwa
...
```

Finally, we use `xargs` to submit a job for each entry:
```console
xargs -P10 -I {} sh -c 'dx run stepcount -iinput_file=":{}" -y --brief' < my-files.txt | tee my-jobs.txt
```
This will execute `dx run stepcount ...` for each entry in `my-files.txt`. It will also create a log file `my-jobs.txt` containing the list of submitted job IDs.

For additional batch processing strategies, see the tutorial by the UK Biobank team:
[https://github.com/UK-Biobank/UKB-RAP-Imaging-ML/blob/main/stepcount-applet/bulk\_files\_processing.ipynb](https://github.com/UK-Biobank/UKB-RAP-Imaging-ML/blob/main/stepcount-applet/bulk_files_processing.ipynb)

### Terminating multiple jobs

If you need to terminate multiple job submissions, the `my-jobs.txt` file can be used as follows:
```console
xargs -P10 -I {} sh -c 'dx terminate "{}"' < my-jobs.txt
```

### Collating results from multiple runs

After running multiple jobs, you may want to merge their output files for further analysis. The `stepcount` package includes a secondary CLI tool, `stepcount-collate-outputs`, made for this purpose. To use it on DNAnexus, you'll need to create a separate applet (you can reuse the previously created asset, avoiding the time-consuming build process).

Follow these steps to build the applet:

1. Open **stepcount-collate-outputs/dxapp.json** and find the `"assetDepends"` field:

   ```text
   "assetDepends": [
     {
       "id": "record-..."
     }
   ]
   ```

   Replace `"record-..."` with the asset ID you created earlier (i.e. `stepcount-asset`).

2. Build the applet:

   ```console
   dx build stepcount-collate-outputs
   ```

Once built, the applet can be run as follows:
```console
dx run stepcount-collate-outputs -iinput_file=my-outputs.txt
```

First, create the `my-outputs.txt` file listing the file IDs to collate. Assuming the files are in the "outputs/" folder, run:
```console
dx find data --path outputs/ --brief > my-outputs.txt
```

This generates a file like:
```text
project-GXJBY38JZ32Vb0588YVYx3Gy:file-Gx4k9hjJVz2Gb3gkV0p3XfVk
project-GXJBY38JZ32Vb0588YVYx3Gy:file-Gx4k9hjJVz28pPjj9p7vJqkX
project-GXJBY38JZ32Vb0588YVYx3Gy:file-Gx4k9hjJVz2P260x2PjZK0Gy
...
```
Note that, unlike the earlier file that listed paths, this one lists file IDs.

Next, upload the list to DNAnexus:
```console
dx upload my-outputs.txt
```
Finally, run the collate applet on that list:
```console
dx run stepcount-collate-outputs -iinput_file=my-outputs.txt
```

#### Speed up file collating by selecting only needed files

If you're working with hundreds of thousands of runs (e.g. UK Biobank), collating everything may be too slow.

The `stepcount` package creates several output types. For example, `*-Info.json` files have overall stats, `*-Daily.csv` files have daily summaries, and `*-Hourly.csv` files show hourly data.

You can speed things up by selecting only the files you need, usually the `*-Info.json` files.

To create a list of just those, run:

```console
dx find data --path outputs/ --brief --name *-Info.json > only-info-outputs.txt
```
