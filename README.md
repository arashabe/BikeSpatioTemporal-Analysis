# **Urban Bike-Sharing: A Spatio-Temporal Analysis of Washington, DC**  

## **Overview**  
This project analyzes Washington, DC’s bike-sharing system using spatio-temporal models to identify demand patterns and optimize urban mobility. By integrating bike rental data with weather and temporal variables, it evaluates the impact of external factors on usage and compares predictive models. Developed as part of the course [**Statistics for High Dimensional Data and CompstatLab**](https://unibg.coursecatalogue.cineca.it/insegnamenti/2024/8244_43632_21827/2021/8244/89?coorte=2023&schemaid=77316) (Master’s in Computer Engineering).  

## **Objectives**  
- Investigate how weather and time variables influence bike-sharing demand.  
- Compare **Dynamic Coregionalization Model (DCM)** and **Hidden Dynamic Geostatistical Model (HDGM)** for predictive accuracy.  
- Propose data-driven strategies to optimize bike allocation and service efficiency. 

- The key questions are:

    - How do weather and events (like holidays) affect bike usage?

    - Which spatio-temporal model (DCM or HDGM) predicts bike usage more accurately? 

## **Methodology**  
- **Data Preprocessing & EDA**: Cleaned and analyzed data using **Python** (Pandas, NumPy, Matplotlib/Seaborn).  
- **Modeling**:  
  - **DCM**: 
      - Hierarchical model capturing spatial-temporal dependencies. 
      - Accounts for both spatial and temporal correlations.
      - Uses two latent components: one for spatial dependencies w(s,t) and one for temporal dynamics z(t).
      - More complex but flexible. 
  - **HDGM**: 
      - Latent process model for dynamic geospatial patterns.  
      - Simpler, with only one latent component z(s,t) for spatio-temporal dynamics.
      - Less prone to overfitting.

- **Tools**: Implemented in **MATLAB (D-STEM v2)** for modeling, validated via cross-validation.  

### Data Exploration

  ### Hourly Rentals
  <br>
  <img src="images/Hourly-Bike-Rentals.png" alt="Hourly Rentals" width="500"> 
  <br> 
  Figure 1: Distribution of rentals across hours of the day.

  ### Daily Rentals
  <br>
  <img src="images/Distribution-of-Bike-Rentals-Hour.png" alt="Daily Rentals" width="500"> 
  <br> 
  Figure 2: Distribution of rentals across hours of the day.

  ### Monthly Trends
  <br>
  <img src="images/Distribution-Bike-Rentals-Months.png" alt="Monthly Trends" width="500">  
  <br>
  Figure 3: Monthly usage variations across 2023.

  ### Seasonal Trends
  <br>
  <img src="images/Distribution-Bike-Rentals-Seasons.png" alt="Seasonal Trends" width="500"> 
  <br> 
  Figure 4: Comparative demand across seasons.


## **Key Findings**  
- **Temperature, precipitation, and UV index** are key demand predictors.  
- Longer trips on weekends/holidays reflect recreational vs. commuting use.  

## **Future Work**  
Expand with socio-demographic data, real-time traffic integration, and multi-year analysis.  

## **References**  
- Finazzi, F., Wang, Y., & Fassò, A. (2021). [D-STEM v2](https://www.jstatsoft.org/index.php/jss/article/view/v099i10). *Journal of Statistical Software*, 99(10).  
- [Capital Bikeshare Data](https://capitalbikeshare.com/system-data) | [Visual Crossing Weather](https://www.visualcrossing.com/weather-data)  
