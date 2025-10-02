# DNAnexus applet for the `stepcount` Python package

Scripts, configuration files, and instructions to create a DNAnexus applet for the Python package `stepcount` (https://github.com/OxWearables/stepcount) for use on the DNAnexus platform.

## ✅ Prerequisites
- Python 3.8 or higher
- The DNAnexus `dx` toolkit: `pip install dxpy`
- git

The following shows how to use Anaconda to satisfy the above prerequisites (you can use any Python environment manager):

1. Download & install [Miniconda](https://docs.conda.io/en/latest/miniconda.html) (light-weight version of Anaconda).
1. (Windows only) Open the **Anaconda Prompt** (Start Menu).
1. Create a new environment named `dxpy` with Python, Pip, and Git:
    ```console
    conda create -n dxpy python=3.9 pip git jq
    ```
1. Activate the environment:
    ```console
    conda activate dxpy
    ```
    You should now see `(dxpy)` at the beginning of your command prompt.
1. Install `dxpy`:
    ```console
    pip install dxpy
    ```

🟢 **You are now ready!** You've created an environment called `dxpy` containing the DNAnexus CLI.

> 🔁 **Next time**:
> Just open the Anaconda Prompt and run:
>
> ```bash
> conda activate dxpy
> ```
>
> If you see `(dxpy)` in your prompt, you’re good to go.

## 🔐 DNAnexus Login & Basic Commands

Log in to DNAnexus:

```bash
dx login
```

Use your regular DNAnexus username/password.

Basic DNAnexus commands (prefixed with `dx`) mimic Unix commands:

| Command    | Meaning               |
| ---------- | --------------------- |
| `dx ls`    | List files/folders    |
| `dx cd`    | Change directories    |
| `dx mkdir` | Create a new folder   |
| `dx rm`    | Delete a file         |
| `dx mv`    | Move or rename a file |

📖 For more: [DNAnexus CLI Quickstart](https://documentation.dnanexus.com/getting-started/cli-quickstart)

## 🛠️ Building the Applet

1. Clone this repository:
    ```console
    git clone https://github.com/OxWearables/dnanexus-stepcount.git
    cd dnanexus-stepcount/
    ```

1. Build the asset:
    ```console
    dx build_asset stepcount-asset
    ```
    ⏳ This takes 10–15 minutes and may show warnings&mdash;ignore them.
    
1. When complete, **copy the asset ID** (e.g., `record-abc123`).
   If you missed it:

   ```bash
   dx describe stepcount-asset
   ```

1. Open the file `stepcount/dxapp.json` find this section:
    ```text
    "assetDepends": [
      {
        "id": "record-..."
      }
    ]
    ```
   Replace `"record-..."` with the actual asset ID. Save and close.

1. Finally, build the applet:
    ```
    dx build stepcount
    ```

## ▶️ Running the Applet

To begin, download a sample accelerometer file:

https://wearables-files.ndph.ox.ac.uk/files/data/samples/ax3/tiny-sample.cwa.gz

and upload it to your DNAnexus project: `dx upload tiny-sample.cwa.gz`

You can now run the applet on the uploaded sample file:
```console
dx run stepcount -iinput_file=tiny-sample.cwa.gz
```
⏳ This takes 5–10 minutes.

This starts a new job on DNAnexus.
The job ID shown in the output (e.g. `job-AbCdE12345`) can be used to track its progress in the DNAnexus web interface under the “Monitor” tab.
Once the job finishes, an `outputs/` folder will be created in your project. You can view its contents with `dx tree outputs/` which should look like this:

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

## 🧯 Troubleshooting

- Error: ('destination project is in region aws:xx-xxxx-x but "regionalOptions" do not contain this region. Please, update your "regionalOptions" specification',)
    - Solution: Open **stepcount/dxapp.json** and search for the `"regionalOptions"` field:
        ```text
        "regionalOptions": {
            "aws:eu-west-2": {...}
        }
        ```
        Change `"aws:eu-west-2"` to your project region as indicated in your error message.

## 🔁 Running on Multiple Files

The most straightforward way to process multiple files is to submit one `dx run` command per file. The example below shows how to automate this using standard Unix commands (it also works in the Windows Anaconda Prompt).

First, you'll need to generate a list of file paths you want to process. In this example, we're working with UK Biobank accelerometer data (about 100,000 files). We use the [`dx find data`](https://documentation.dnanexus.com/user/objects/searching-data-objects#searching-across-objects-in-the-current-project) command to filter by field ID 90001 (UK Biobank ID for accelerometry), and then use [`awk`](https://en.wikipedia.org/wiki/AWK) to extract just the file paths:

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

Finally, we use [`xargs`](https://en.wikipedia.org/wiki/Xargs) to submit a job for each entry:
```console
xargs -P10 -I {} sh -c "dx run stepcount -iinput_file=:{} -y --brief" < my-files.txt | tee my-jobs.txt
```
This will execute `dx run stepcount ...` for each entry in `my-files.txt`. It will also create a log file `my-jobs.txt` containing the list of submitted job IDs.

For additional batch processing strategies, see the tutorial by the UK Biobank team:
[https://github.com/UK-Biobank/UKB-RAP-Imaging-ML/blob/main/stepcount-applet/bulk\_files\_processing.ipynb](https://github.com/UK-Biobank/UKB-RAP-Imaging-ML/blob/main/stepcount-applet/bulk_files_processing.ipynb)

### 🔍 Monitoring Jobs
To monitor the submitted jobs, the `my-jobs.txt` file can be used as follows:
```console
xargs -P10 -I {} sh -c "dx describe {} --json | jq -r .state" < my-jobs.txt | sort | uniq -c
```

### 🛑 Terminating Jobs

If you need to terminate the submitted jobs, the `my-jobs.txt` file can be used as follows:
```console
xargs -P10 -I {} sh -c "dx terminate {}" < my-jobs.txt
```

## 📊 Collating Outputs from Multiple Runs

After running multiple jobs, you may want to merge their output files for further analysis. The `stepcount` package includes a secondary CLI tool, `stepcount-collate-outputs`, made for this purpose. To use it on DNAnexus, you'll need to create a separate applet (you can reuse the already created `stepcount-asset` asset, avoiding the time-consuming asset building process):

1. Open **stepcount-collate-outputs/dxapp.json** and find this section:

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

The applet can then be used as follows:
```console
dx run stepcount-collate-outputs -iinput_file=my-outputs.txt
```

First, create the `my-outputs.txt` file listing the IDs of the files you want to collate. We will use [`dx find data`](https://documentation.dnanexus.com/user/objects/searching-data-objects#searching-across-objects-in-the-current-project) for this. Assuming the files are in the `outputs/` folder, run:
```console
dx find data --path outputs/ --brief > my-outputs.txt
```

The resulting `my-outputs.txt` file will look like this:
```text
project-GXJBY38JZ32Vb0588YVYx3Gy:file-Gx4k9hjJVz2Gb3gkV0p3XfVk
project-GXJBY38JZ32Vb0588YVYx3Gy:file-Gx4k9hjJVz28pPjj9p7vJqkX
project-GXJBY38JZ32Vb0588YVYx3Gy:file-Gx4k9hjJVz2P260x2PjZK0Gy
...
```
Note that, unlike the `my-files.txt` file from the previous section which listed file paths, this one lists file IDs.

Next, upload the list to DNAnexus:
```console
dx upload my-outputs.txt
```
Finally, run the collate applet on the list:
```console
dx run stepcount-collate-outputs -iinput_file=my-outputs.txt
```

#### 💡 Tip: Speed Up File Collating by Selecting Only Needed Files

If you're dealing with hundreds of thousands of output files (e.g. UK Biobank), collating everything may be too slow.

The `stepcount` package creates several output types. For example, `*-Info.json` files have overall stats, `*-Daily.csv` files have daily summaries, and `*-Hourly.csv` files show hourly data.

You can speed things up by selecting only the files you need using the `--name` option in the `dx find data` command. For example, if you only want the `*-Info.json` files:

```console
dx find data --path outputs/ --brief --name *-Info.json > only-info-outputs.txt
```

## 📌 Versioning for Reproducibility

To ensure reproducibility and follow best practices, we recommend explicitly pinning the version of the `stepcount` package in your asset.

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

Find all available versions of `stepcount` here:
👉 [https://github.com/OxWearables/stepcount/releases](https://github.com/OxWearables/stepcount/releases)
