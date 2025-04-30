install.packages("ggplot2")
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg))
p + geom_point(aes(size = qsec, colour = factor(cyl))
               
               library(ggplot2)
               library(ggfortify)
               install.packages("tidyverse")
               install.packages("prophet")
               library(prophet)
               library(tidyverse)
               
               
AR1 <- list(order = c(1,0,0), ar = 0.5, sd = 0.01) 
AR1 <- arima.sim(n = 10000, model = AR1) 
MA1 <- list(order = c(0,0,1), ma = 0.7, sd = 0.01) 
MA1 <- arima.sim(n = 10000, model = MA1) 
ARMA11 <- list(order = c(1,0,1), ar = 0.5, ma = 0.5, sd = 0.01)
ARMA11 <- arima.sim(n = 10000, model = ARMA11) 
#Graphing the Three Series 
combo <- cbind(AR1,MA1,ARMA11) 
autoplot(combo, facets = TRUE) + ggtitle("Time Series Plots") 
par(mfrow = c(1,2)) 
#Comparing their ACF and PACF 
#For the AR 
acf(AR1) #Geometric Decay 
pacf(AR1) #Cutoff after first lag 
#For the MA 
acf(MA1) #Cutoff after first lag 
pacf(MA1) #Geometric Decay 
#For the ARMA 
acf(ARMA11) #Geometric Decay 
pacf(ARMA11) #Geometric Decay 
par(mfrow = c(3,3)) 
plot.ts(AR1) 
acf(AR1) #Geometric Decay 
pacf(AR1) #Cutoff after first lag 
plot.ts(MA1) 
acf(MA1) #Cutoff after first lag 
pacf(MA1) #Geometric Decay 
plot(ARMA11) 
acf(ARMA11) #Geometric Decay 
pacf(ARMA11) #Geometric Decay

install.packages("prophet")

"uploade the data cvs"
bit <- read.csv(file.choose())
head(bit) " chech the data"
modelb <- prophet(bit, daily.seasonality=TRUE, ) "fit the p models"
fut <- make_future_dataframe(modelb, periods= 365, confint.default(modelb))",ake some fut forecasrt"
tail(fut)

forecastact<- predict(modelb , fut)
tail(forecastact[c("ds" , "yhat" , "yhat_lower" , "yhat_upper")])

 dyplot.prophet(modelb, forecastact) 
 prophet_plot_components(modelb, forecastact)

library(tidyverse)
 
 library(ggplot2)

 library(ggfortify)

library(forecast)
 library(urca)
 library(tseries)
 library(TSstudio)
 
 inf <- read.csv(file.choose())
 head(inf)
nrow(inf)


"ts var"
 infs <- ts(inf$Rate, start =  c(2000,1,5), frequency= 12)

autoplot(infs) + ggtitle("inf rate") + labs(x= "Time in Years" , y= "Rate")
"not stat"

summary(infs)

"ggacf.. lib=forcast)"

ggAcf(infs) "ar decay"
ggPacf(infs) " ar- abrupt cuttoff, some lags sig- not stat"

difinf<- diff(infs)
ggAcf(difinf) "geo decay"
ggPacf(difinf)

ts_decompose(infs, type="add", showline = TRUE)

"NONstat- test for stat"

adf.test(difinf, k = 2) "d is stat, not og, i = 1"
pp.test(difinf)
kpss.test(difinf)

"training and test sets"

split_infs <- ts_split(infs, sample.out = 12)

train <- split_infs$train 
test<- split_infs$test

length(train)
length(test)

arima_diag(train)
"k=2"

ari <- arima(train, c(2,1,1))
ari
autoplot(ari)
 ' unit crle , dot is in the crle = stable'
 
 check_res(ari)"the 12 lag is sig =  some sesoanality in the training model"
 
 sari<- arima(train, order = c(2,1,1), seasonal = list(order=c(1,0,0)))
 autoplot(sari)
check_res(sari) "lag is 24, naot as sig"

autoari<- auto.arima(train, seasonal = TRUE)
 autoplot(autoari)
 check_res(autoari)
 autoari

 ft<- forecast(autoari, h=12) 
ft
test_forecast(infs, forecast.obj = ft, test = test )
 
 accuracy(ft, test)
 
 bb<- auto.arima(infs, seasonal= TRUE)
FBB<- forecast(infs, model=bb, h=24)
plot_forecast(FBB)


              
              method <- list(
                Model1 = list(
                  method = "arima",
                  method_arg = list(order = c(2, 1, 1)),
                  notes = "Ari211"
                ),
                Model2 = list(
                  method = "arima",
                  method_arg = list(
                    order = c(2, 1, 1),
                    seasonal = list(order = c(1, 0, 0))
                  ),
                  notes = "SARMIA_211/100"
                ),
                Model3 = list(
                  method = "arima",
                  method_arg = list(
                    order = c(2, 1, 1),
                    seasonal = list(order = c(2, 0, 1))
                  ),
                  notes = "Model3 with seasonal 201"
                )
              )
              md <- train_model(
                input = infs,
                methods = method, 
                train_method = list(
                  partitions = 2,
                  sample.out = 12,
                  space = 3,
                  optim.method = "Nelder-Mead"  # Use a more robust optimization method
                ),
                horizon = 12,
                error = "RMSE"
              )
              
              
              
              
              
              
              
              
              
              
        install.packages(mFilter)      
              
        library(mFilter)
        library(prophet)
        library(tidyverse)
        library(vars)
        library(ggplot2)
        library(ggfortify)
        library(forecast)
        library(urca)
        library(tseries)
        library(TSstudio)
      "cointer"
      
      data <- read_csv(file.choose())
      head(data)
      #Declare Time Series Objects
      GDP <- ts(data$lnGDP, start = c(2003,1,31), frequency = 4)
      CPI <- ts(data$lnCPI, start = c(2003,1,31), frequency = 4)
      M3 <- ts(data$lnM3, start = c(2003,1,31), frequency = 4)
      gdp
      #Bind into a system
      dset <- cbind(GDP,CPI,M3)
      #Lag Selection Criteria
      lagselect <- VARselect(dset, lag.max = 7, type = "const")
      lagselect$selection
      #Since 5 was chosen, we use 5 - 1 = 4
      #Johansen Testing (Trace)
      ctest1t <- ca.jo(dset, type = "trace", ecdet = "const", K = 4)
      summary(ctest1t)
      #Johansen Testing (MaxEigen)
      ctest1e <- ca.jo(dset, type = "eigen", ecdet = "const", K = 4)
      summary(ctest1e)
        
  " impact causality"      
  
library(CausalImpact
        )
        
    ce <- read.csv(file.choose()) 
    head(ce)
        
        
        time.points <- seq.Date(as.Date("2020-02-27"),by = 1, length.out = 44)
        
        
        v <- ts(ce$VIX)
        
        i <- ts(ce$IBCL)
        u <- ts(ce$US10Year)
        
        co <- cbind(v,i,u)
         finaldat <- zoo(co, time.points)
        
        
        head(finaldat)
        
        before <- as.Date(c("2020-02-27", "2020-03-23"))
        after <- as.Date(c(" 2020-03-24", "2020-04-10"))
        
      ci <-CausalImpact(finaldat,before,after)
      plot(ci)
        summary(ci)
        "var"
        
 okun <- read.csv(file.choose())              
              
    ggplot(data = okun) + geom_point(mapping = aes(x=unem, y= real_gdp_growth )) 
    + ggtitle("Scatter gdp/Unem")              
          
              
  gdp <- ts(okun$real_gdp_growth, start = c(1999,3), frequency = 4)
              
 unem <- ts(okun$unem, start = c(1999,3), frequency = 4)
             
              autoplot(cbind(gdp, unem))"cb same scale if simialr time"
              
         
              " var both var are dep"
              OLS1 <- lm(gdp ~ unem) "lm - gdp is dep, unem indep"
              
              summary(OLS1)
              autoplot(OLS1)
              plot(OLS1)
              
              #Determine the Persistence of the Model
              
            #MAIN = to name 
              
              acf(gdp, main = "ACF for Real GDP Growth")
              
              pacf(gdp, main = "PACF for Real GDP Growth")
              
              acf(unem, main = "ACF for Unemployment")
              
              pacf( unem,  main = "PACF for Unemployement")
              
              OLS1 <- lm(gdp ~ unem)
              
              summary(OLS1)
              
      
              
              #Finding the Optimal Lags
              # var =  ar lags
              
              okun.bv <- cbind(gdp, unem)"group them"
              
              colnames(okun.bv) <- cbind("GDP", "Unemployment")

              install.packages("vars")
              library(vars)
              
                            
              lagselect <- VARselect(okun.bv, lag.max = 10, type = "const")
              # type is the trend
              
              lagselect$selection
              
              #Building VAR
              
              mo <- VAR(okun.bv, p = 4, type = "const", season = NULL, exog = NULL)
              
              summary (Model0kun1)              
              "plot.ts(Model0kun1, NULL, log = list(order = c(1,0,0)), setLab = FALSE)"
              
              # acorr 
               
              Serial <- serial.test(mo, lags.pt = 12, type = "PT.asymptotic")
              Serial
              
              
              
              
              
              
                          
              ## arch
              arch <- arch.test( mo, lags.multi = 12, multivariate.only = T)
              arch
              
              #norm res
              
              norm <- normality.test(mo, multivariate.only = TRUE) 
              stab <- stability(mo, type = "OLS-CUSU") 
              
              
              
              plot(norm,stab)
              
              plot(stab)
              
            causality(mo, cause = "GDP")
            
            
           i <- irf(mo, impuse = "Unemployment", response = "GDP", n.ahead = 29,
                boot = T , cumulative  = F , ci = 0.05, runs = 100 )
                            
            plot(i, ylab =  "RGDP", main = "Shock for Unem")
            
            
            vd<- fevd(mo, n.ahead = 10, )
            
          plot(vd)
          
          forecast <- predict(mo, n.ahead = 4)
          fanchart(forecast, names = "GDP")
          
          
          
          
          "svar"
          
          macro <- read_csv(file.choose())
          head(macro)
          #Creating thee Time Series Objectives
          y <- ts(macro$`Output Gap`, start = c(2000,1,1), frequency = 4)
          pi <- ts(macro$CPI, start = c(2000,1,1), frequency = 4)
          r <- ts(macro$RRP, start = c(2000,1,1), frequency = 4)
          #Time Series Plots
          ts_plot(y, title = "Output Gap", Xtitle = "Time", Ytitle = "Output Gap")
          ts_plot(pi, title = "Inflation Rate", Xtitle = "Time", Ytitle = "Inflation Rate")
          ts_plot(r, title = "Overnight Reverse Repurchase Rate", Xtitle = "Time", Ytitle = "RRP")
          #Setting the Restrictions sim effects - id 
          amat <- diag(3)"3 vari, its a id matrix"
          amat[2,1] <- NA
          amat[3,1] <- NA
          amat[3,2] <- NA
          amat
          "[r,c] na is for what it cant effecT, 0 is rest, na will be esti by sys"
          #Buidling the Model
          sv <- cbind(y, pi, r)
          colnames(sv) <- cbind("OutputGap", "Inflation", "RRP")
          lagselect <- VARselect(sv, lag.max = 8, type = "both")
          lagselect$selection
          lagselect$criteria
          
          #first est var then impse ret
          Model1 <- VAR(sv, p = 5, season = NULL, exog = NULL, type = "const")
          SVARMod1 <- SVAR(Model1, Amat = amat, Bmat = NULL, hessian = TRUE, estmethod =
                             c("scoring", "direct"))
          SVARMod1
          #Impulse Response Functions
          SVARog <- irf(SVARMod1, impulse = "OutputGap", response = "OutputGap", ci = 0.01)
          SVARog
          plot(SVARog)
          SVARinf <- irf(SVARMod1, impulse = "OutputGap", response = "Inflation")
          SVARinf
          plot(SVARinf)
          SVARrrp <- irf(SVARMod1, impulse = "Inflation", response = "RRP")
          SVARrrp
          plot(SVARrrp)
          #Forecast Error Variance Decomposition
          SVARfevd <- fevd(SVARMod1, n.ahead = 10)
          SVARfevd
          plot(SVARfevd)
          
          
          
          
          
          
          "VECM"
          
          
          
          install.packages("tsDyn")
          library(tsDyn)
          library(vars)
          
          ########################################
          #JOHANSEN COINTEGRATION in R
          ########################################
          
          #Calling the packages for use
          
          library(urca)
          library(forecast)
          library(tidyverse)
          
          
          
          #Loading the Dataset
          
          data <- read_csv(file.choose())
          head(data)
          
          #Declare the Time Series Objects
          
          GDP <- ts(data$lnGDP, start = c(2003,1,31), frequency = 4)
          CPI <- ts(data$lnCPI, start = c(2003,1,31), frequency = 4)
          M3 <- ts(data$lnM3, start = c(2003,1,31), frequency = 4)
          
          #Creating our System
          
          dset <- cbind(GDP,CPI,M3)
          
          #Selecting the Optimal Number of Lags (Recall, this is p - 1)
          
          lagselect <- VARselect(dset, lag.max = 7, type = "const")
          lagselect$selection
          lagselect$criteria
          #Since 5 came up the most, we use (5-1) or 4 lags
          
          ctest1t <- ca.jo(dset, type = "trace", ecdet = "const", K = 4)
          summary(ctest1t)
          
          ctest1e <- ca.jo(dset, type = "eigen", ecdet = "const", K = 4)
          summary(ctest1e)
          
          #Hence, we have one cointegrating relationship in this model
          
          ######################################################################
          
          #Build the VECM Model
          " 4 LAGS FROM CG, 1 IS COINT EQ"
          
          Model1 <- VECM(dset, 4, r = 1, estim =("2OLS"))
          summary(Model1)
          
          #Diagnostic Tests
          
          #Need to Transform VECM to VAR
          
          Model1VAR <- vec2var(ctest1t, r = 1)
          
          #Serial Correlation
          
          Serial1 <- serial.test(Model1VAR, lags.pt = 5, type = "PT.asymptotic")
          Serial1
          
          #ARCH Effects
          
          Arch1 <- arch.test(Model1VAR, lags.multi = 15, multivariate.only = TRUE)
          Arch1
          
          #Normality of Residuals
          
          Norm1 <- normality.test(Model1VAR, multivariate.only = TRUE)
          Norm1
          
          #Impulse Response Functions
          
          M3irf <- irf(Model1VAR, impulse = "GDP", response = "M3", n.ahead = 20, boot = TRUE)
          plot(M3irf, ylab = "M3", main = "GDP's shock to M3")
          
          CPIirf <- irf(Model1VAR, impulse = "GDP", response = "CPI", n.ahead = 20, boot = TRUE)
          plot(CPIirf, ylab = "CPI", main = "GDP's shock to CPI")
          
          GDPirf <- irf(Model1VAR, impulse = "GDP", response = "GDP", n.ahead = 20, boot = TRUE)
          plot(GDPirf, ylab = "GDP", main = "GDP's shock to GDP")
          
          #Variance Decomposition
          
          FEVD1 <- fevd(Model1VAR, n.ahead = 10)
          plot(FEVD1)
          
          
          
          
          
          