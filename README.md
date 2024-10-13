TPC-DS BENCHMARKING POSTGRESQL
# Introduction
This repository contains the code files and the corresponding explanation of the first project conducted for the course Data Warehouses, which is part of the Big Data Management and Analytics (BDMA) - Erasmus Mundus Joint Master Degree Program. It aims to enable other users to replicate our findings and to provide a clearer explanation of the steps involved in conducting a meaningful TPC-DS benchmark for individuals interested in open-source solutions.

## Prerequisites
To proceed with this project, the user must have Docker, Ubuntu Docker Image, and PostgreSQL already downloaded and installed. If these are not yet available, they can be obtained from the following links:

- [Docker](https://www.docker.com/products/docker-desktop/)
- [Ubuntu Image](https://hub.docker.com/_/ubuntu)
- [PostgreSQL](https://www.postgresql.org/)

In addition, you should download the TPC-DS official files from the official website to follow this guide. The link is written below:

- [TPC-DS](https://www.tpc.org/tpc_documents_current_versions/current_specifications5.asp)

Finally, you will need the following files:

- `preprocess_db_setup_load_script.py`

You can download them by downloading the folder called “Necessary files”. These files were originally found in the following repository [here](https://github.com/risg99/tpc-ds-benchmark), but they have been updated to fit our file architecture and setup.

Thank you!

## File architecture
During this project, we will work with the following file architecture:

```
Project
└── TPC-DS (Official files)
    └── preprocess_db_setup_load_script.py
```

Ensure your files are correctly organized if you want to run our code.

## Step-by-step guide
We will divide this step-by-step guide into three sections. First, we will update some of the official TPC-DS files to prevent errors. Second, we will build the TPC-DS data using Ubuntu. Finally, we will create the database and load the data.

### DOWNLOAD AND INSTALLATION
To start this benchmark, start by downloading this repository to your computer and then unzip the folder. After that, locate the folder named DSGen-software-code-3.2.0rc1 within the TPC-DS official files and move it into the repository folder. Lastly, create a new folder inside the repository and name it "data". Your file structure should look like this:

```
tpcds-benchmark-main
└── all_queries
└── data
└── DSGen-software-code-3.2.0rc1 
└── ...
```

### TPC-DS DATA AND QUERY BUILD:
Let’s begin with the preparation of the data and queries that we will use to perform our benchmark.

1. Open a terminal and build the docker image using the following command:
    ```sh
    docker build --tag tpcda:ubuntu
    ```
    That should take a few seconds.

2. Run the following command in the terminal:
    ```sh
    docker compose up
    ```
   This should take a couple of minutes. After your data and queries should have been already built. 

We are ready to jump to the next section. You can check now your data folder. You should find inside many csv files with the data.

### CREATING THE DATABASE:
In this section, we will first create the database and bulk-load the data into it. We will need the file `preprocess_db_setup_load_script.py`. We should run this file inside of the folder `TPC-DS-Built`, so put it inside before continuing.

#### Step 1: Set Up a Virtual Environment
Create a virtual environment and install the required dependencies.
```bash
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

#### Step 2: Set Up Jupyter Notebook Kernel
Create an IPython kernel in your virtual environment to use it with Jupyter.
```bash
ipython kernel install --user --name=tpc_ds_kernel
python -m ipykernel install --user --name=tpc_ds_kernel
python -m bash_kernel.install
```

#### Step 3: Replace the file tpcds_ri.sql 
Use the file `tpcds_ri.sql` from the current repository to replace the file at your `TPC-DS-Built>tools>tpcds_ri.sql` to fix potential upcoming constraint creation errors.

#### Step 4: Start Jupyter Notebook
Start Jupyter notebook and open the file `preprocess_db_setup_load_script.ipynb` that is stored inside of the folder `TPC-DS-Built` and then switch the kernel to `tpc_ds_kernel`. Also, in the second cell of the notebook change the port and password of PostgreSQL to the ones that your program uses. Now execute all the cells of the notebook.


This repository contains the code files and the corresponding explanation of the first project conducted for the course Data Warehouses, which is part of the Big Data Management and Analytics (BDMA) - Erasmus Mundus Joint Master Degree Program. It aims to enable other users to replicate our findings and to provide a clearer explanation of the steps involved in conducting a meaningful TPC-DS benchmark for individuals interested in open-source solutions.
