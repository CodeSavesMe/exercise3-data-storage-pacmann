# Exercise 3 — Data Storage

**Program:** Data Storage, Sekolah Engineering, Pacmann

## Outline

- [Objective](#objective)
- [Dataset](#dataset)
- [Task Description](#task-description)
  - [Step #1 — Requirements Gathering (10 points)](#step-1--requirements-gathering-10-points)
  - [Step #2 — Designing Data Warehouse Model (20 points)](#step-2--designing-data-warehouse-model-20-points)
  - [Step #3 — Data Pipeline Implementation (50 points)](#step-3--data-pipeline-implementation-50-points)
  - [Step #4 — Show Results of the Pipeline (20 points)](#step-4--show-results-of-the-pipeline-20-points)
  - [Step #5 — Create Report](#step-5--create-report)

## Objective

The objective of this exercise is to:

- Create a Data Warehouse schema
- Create an ELT pipeline using dbt

## Dataset

The dataset is based on a travel domain with multiple entities capturing different aspects of the travel process. It includes details about:

- aircrafts
- airlines
- airports
- customers
- hotels
- flight bookings
- hotel bookings

The user will likely need analysis focused on understanding trends in flights, hotels, and customer behavior. Below are some possible analytical needs for the user:

- **Track daily booking volumes**  
  Understand how many bookings are made for flights and hotels each day.

- **Monitor average ticket prices over time**  
  Analyze how ticket prices fluctuate, which can indicate changes in demand and inform pricing strategies.

To support these analytical needs, we will enhance the data warehouse design and provide tables that facilitate analysis.

## Task Description

### Step #1 — Requirements Gathering (10 points)

In this stage, you are required to understand the data to be used, its source, format, and context, analyze stakeholder data needs, and propose a solution to address the problems faced by the stakeholders.

**Data Source Used:**  
PacTravel

You can access the data source in the following Docker repository:  
`https://github.com/Kurikulum-Sekolah-Pacmann/pactravel-dataset.git`

**Output:** Describe your understanding of the data source and reiterate the user's needs.

Required sections:

- *Description*
- *Problem*
- *Solution*

---

### Step #2 — Designing Data Warehouse Model (20 points)

In this step, you will design the dimensional model for the Data Warehouse based on the requirements gathered in Step #1. This includes:

- Design dimensional model process
- Select business process
- Declare grain
- Identify the dimension
- Identify the fact
- Use at least 2 types of fact tables  
  *(Explain in the documentation so that it can be understood by reviewers)*
- Slowly Changing Dimension strategy

**Output:**  
Describe the dimensional model design and its components, explaining how it addresses the user's needs.

**Example Output:**

- **Select Business Process:** Order Transaction
- **Declare Grain:**
  - A single data represents a purchased product by a customer
  - A single data represents daily total transaction for each product
- **Identify the Dimension:**
  - `dim_customer`
  - `dim_date`
- **Identify the Fact:**
  - `fct_order_transaction`
  - `fct_daily_total`
- **Diagram Data Warehouse:** ERD
- **SCD Strategy**

---

### Step #3 — Data Pipeline Implementation (50 points)

In this step, you will implement the ELT (Extract, Load, Transform) workflow for the Data Warehouse using Python, Luigi, and dbt. This involves extracting data from the source, loading it into a staging area, and transforming it into the Data Warehouse.

This step includes:

- Data pipeline implementation
- Scheduling
- Alerting

**Output:**  
Describe the implementation of the ELT workflow, detailing the tools and technologies used, as well as the steps involved in the extraction, transformation, and load process.

**Example Output:**

- **Workflow**
  - Extract and load data from database source to database warehouse schema staging using Python
  - Transform and load data from schema staging to schema data warehouse using dbt

- **Your Code Repository**

---

### Step #4 — Show Results of the Pipeline (20 points)

Run the completed ELT pipeline and showcase the results.

You should:

- Display some transformed data loaded into the final Data Warehouse tables
- Verify that the output matches the business requirements by showing example queries or reports that leverage the final dataset
- Ensure that the pipeline has successfully transformed the data as expected by running sample queries to demonstrate key insights or results from the Data Warehouse

---

### Step #5 — Create Report

The report can take the form of:

- an article *(which should include a link to your GitHub project)*, or
- a `README` file on GitHub

Ensure you thoroughly explain all points mentioned above.