libname inusrepricemodel xlsx "/home/u63313980/my_content/ActuarySanalm/sanalm2024/Lifeinusre_motatilty_data.xlsx";

proc gplot data=inusrepricemodel;
plot y*expectancy;
run;

proc arima data=inusrepricemodel;
 identify var=y nlag=24;
 estimate p=2 plot;
 forecast lead=1 out=res;
 ods graphics off;
 ods listing;
run;
/* Simulate Sample Policy Data */
data inusrepricemodel;
    call streaminit(123); /* For reproducibility */
    do policy_id = 1 to 1000;
        age = rand("uniform")*40 + 20; /* Age between 20 and 60 */
        gender = ifc(rand("uniform") < 0.5, "Male", "Female");
        sum_assured = rand("uniform")*90000 + 10000; /* Between 10,000 and 100,000 */
        term = ceil(rand("uniform")*30); /* Term between 1 and 30 years */
        base_mortality_rate = 0.0005 + 0.0001*age; /* Simplified mortality rate */
        lapse_rate = 0.05; /* 5% lapse rate */
        expense_loading = 0.10; /* 10% expense loading */
        profit_margin = 0.05; /* 5% profit margin */
        interest_rate = 0.03; /* 3% annual interest rate */
        output;
    end;
run;

/*  Calculate Traditional Net Premium */
data inusrepricemodel;
    set policy_data;
    /* Present Value of Benefits (PVFB) */
    pvfb = sum_assured * base_mortality_rate * term / ((1 + interest_rate)**term);
    /* Present Value of Premiums (PVFP) */
    pvfp = term / ((1 + interest_rate)**term);
    /* Net Premium */
    net_premium = pvfb / pvfp;
run;

/*  Calculate Gross Premium */
data gross_premium;
    set net_premium;
    gross_premium = net_premium * (1 + expense_loading + profit_margin);
run;

/* Risk-Based Pricing */
data risk_based_pricing;
    set gross_premium;
    /* Adjust premium based on risk factors */
    risk_factor = 1;
    if age > 50 then risk_factor + 0.2;
    if gender = "Male" then risk_factor + 0.1;
    risk_based_premium = gross_premium * risk_factor;
run;

/*  Stochastic Pricing Model */
proc iml;
    /* Parameters */
    n = 1000; /* Number of simulations */
    term = 20;
    sum_assured = 50000;
    base_mortality_rate = 0.005;
    interest_rate_mean = 0.03;
    interest_rate_sd = 0.005;
    expense_loading = 0.10;
    profit_margin = 0.05;

    /* Simulate interest rates */
    call randseed(123);
    interest_rates = randnormal(n, j(1,1,interest_rate_mean), j(1,1,interest_rate_sd));

    /* Calculate PVFB and PVFP for each simulation */
    pvfb = j(n,1,0);
    pvfp = j(n,1,0);
    do i = 1 to n;
        ir = interest_rates[i];
        pvfb[i] = sum_assured * base_mortality_rate * term / ((1 + ir)**term);
        pvfp[i] = term / ((1 + ir)**term);
    end;

    /* Calculate Net and Gross Premiums */
    net_premium = pvfb / pvfp;
    gross_premium = net_premium * (1 + expense_loading + profit_margin);

    /* Output results */
    create stochastic_premium var {"net_premium" "gross_premium"};
    append;
    close stochastic_premium;
quit;

/* Merge all results */
data inusrepricemodel;
    merge risk_based_pricing stochastic_premium;
    by _N_;
run;

/* Display final dataset */
proc print data=final_pricing(obs=10);
    title "Sample Insurance Pricing Calculations";
run;
