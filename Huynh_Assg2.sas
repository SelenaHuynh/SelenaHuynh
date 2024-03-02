/* Generated Code (IMPORT) */
/* Source File: amazon.xlsx */
/* Source Path: /home/u63320131/Assignment2 */
/* Code generated on: 5/15/23, 4:59 PM */

%web_drop_table(WORK.IMPORT);

ods pdf file="~/Huynh_Assignment_2.pdf";
/*
[1]. Which categories receive the most reviews among different product types?
*/

/* Define an empty library AMAZON to save the imported data */
Libname AMAZON '/home/u63320131/Assignment2';

/*
[1.2] Import all data from Excel file  
*/
ods pdf startpage=now; 

%macro import_sheet(file=, sheet=, out= , variable=);
 
filename reffile "&file.";
proc import datafile=reffile
    dbms=xlsx
    out=&out.
    replace;
    sheet="&sheet.";
    getnames=yes;
run;

proc sort data=&out. nodupkey;
	by &variable.; 
run;

%mend import_sheet;

%import_sheet(file='/home/u63320131/Assignment2/amazon.xlsx', sheet=Products, out=Products, variable= product_id);
%import_sheet(file='/home/u63320131/Assignment2/amazon.xlsx', sheet=Reviews, out=Reviews, variable= review_id product_id);
%import_sheet(file='/home/u63320131/Assignment2/amazon.xlsx', sheet=Users, out=Users, variable= user_id);

/* Clean and prepare data*/

data products_cleaned;
	set products;
	category_root = scan(category, 1, '|');
	actual_price_num = input(compress(actual_price, "₹"), comma8.);
	rating_count_num = input(rating_count, comma8.);
	discounted_price_num = input(compress(discounted_price, "₹"), comma8.);
	drop actual_price discounted_price rating_count img_link product_link;
	rename actual_price_num = actual_price rating_count_num = rating_count discounted_price_num = discounted_price;
run;

proc contents data=products_cleaned;
run;


/* Calculate review count by product_id */
proc sql noprint;
  create table review_counts as
  select product_id, count(*) as review_count
  from reviews
  group by product_id;
quit;

/* Merge review_count with the products dataset */
data products_cleaned_review_count;
  merge products_cleaned(in=in1) review_counts(in=in2);
  by product_id;
  if in1;
run;

/* sort the products_cleaned_reviewd_count dataset*/
proc sort data=products_cleaned_review_count out=products_sorted;
	by product_id;
run;

/* sort the Reviews dataset*/
proc sort data=reviews out=reviews_sorted;
	by product_id;
run;


/*merging the sorted datasets of Products and Reviews*/
data products_reviews;
	merge reviews_sorted products_sorted;
	by product_id;
run;

/* Plot a pie chart to show the shares of each products category within the total*/
proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		layout region;
		piechart category=category_root / stat=pct;
		endlayout;
		endgraph;
	end;
title "Shares of each products category within the total";
footnote "*The pie chart compares the relative proportions of a specific product catgory";
footnote2 "*It also shows which categories have a larger or smaller share";
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgrender template=SASStudio.Pie data=WORK.PRODUCTS_CLEANED;
run;
ods graphics / reset;

/* Calculate the average rating count per category */
proc means data=products_reviews noprint nway missing;
	class category_root;
	var rating_count;
	output out=category_avg_rating_count mean=avg_rating_count;
run;

/* Sort the dataset by descending average rating count */
proc sort data=category_avg_rating_count;
	by descending avg_rating_count;
run;

/* Display the top categories with highest average rating count */
proc print data=category_avg_rating_count noobs label;
	title "Top Categories with Highest Average Rating Count";
	footnote "*Product categories with highest average rating count, providing insights into popularity & engagement of different categories among users";
	var category_root avg_rating_count;
	where not missing(category_root) and category_root ne '';
run;

/* Create a pie chart of the rating counts by category */
proc gchart data=category_avg_rating_count;
	pie category_root / sumvar=avg_rating_count;
	label category_root = "Product Category";
	title "Rating Counts by Category (Pie Chart)";
	footnote "*Rating count distribution across product categories, revealing relative frequencies of each category";
run;

/*labels and format*/

data products_cleaned reviews users;
	set products_cleaned reviews users;
	lable product_ID = 'Product ID'
		  product_name = 'Product Name'
		  category = 'Category'
		  category_root = 'Category Root'
		  discounted_price = 'Discounted Price'
		  actual_price = 'Actual Price'
		  rating = 'Rating'
		  rating_count = 'Rating Count'
		  img_link = 'Image Link'
		  product_link = 'Product Link'
		  user_ID = 'User ID'
		  review_ID = 'Review ID'
		  review_title = 'Review Title'
		  review_content = 'Review Content'
		  user_name = 'User Name';
run;

/* 
[2].Does the cost of products correspond to their ratings, with higher-rated ones costing more money? 
*/

/* Calculate the average and maximum products' actual price by rating*/
proc means data=products_cleaned mean max;
	class rating / missing;
	var actual_price;
	output out=avg_price_by_rating mean=avg_actual_price;
	where not missing(rating);
title "Average and maximum Actual Price by Rating Category";
footnote "*This table reveals potential average & maximum price variations based on product ratings";
run;

/* Sort the dataset by rating */
proc sort data=avg_price_by_rating;
	by descending rating;
run;

/* Display the average & maximum actual price for each rating category */
proc print data=avg_price_by_rating noobs label;
	title "Sorted Average Actual Price by Rating Category";
	footnote "*This table reveals potential average price variations based on product ratings";
	ods noproctitle;
	var rating avg_actual_price;
	where not missing(rating);
run;


/*
[3] What effect does discounting have on the number of ratings and reviews obtained?
*/

/* Calculate summary statistics for ratings and reviews */
proc means data=products_reviews noprint;
	var rating_count;
	var review_count;
	output out=summary_stats mean(rating_count)=mean_rating_count mean(review_count)=mean_review_count;
run;

proc tabulate data=summary_stats;
	title "Summary Statistics for Rating Count and Review Count";
	footnote "*Summarized key statistical measures and trends for count of ratigns & reviews";
	var mean_rating_count mean_review_count;
	table mean_rating_count mean_review_count;
run;

/* Create a scatter plot to visualize the relationship between discount and rating count */
title "Relationship between Discounted Price and Rating Count";
footnote "*Notes that regression line summarizes the overall correlation of discounted price and rating count";
proc sgplot data=products_reviews;
	scatter x=discounted_price y=rating_count / markerattrs=(symbol=circlefilled);
	reg x=discounted_price y=rating_count / lineattrs=(color=red);
  	xaxis label="Discounted Price";
  	yaxis label="Rating Count";
run;

/* Create a scatter plot to visualize the relationship between discount and review count */
title "Relationship between Discounted Price and Products Reviews";
footnote "*Notes that regression line summarizes the overall correlation of discounted price and review count";
proc sgplot data=products_reviews;
  	scatter x=discounted_price y=review_count / markerattrs=(symbol=circlefilled);
  	reg x=discounted_price y=review_count / lineattrs=(color=green);
  	xaxis label="Discounted Price";
  	yaxis label="Review Count";
run;

/*
[4]. Which products categories have higher average product prices compared to all other categories?
*/

/* Calculate average product prices by category */
proc means data=products_cleaned noprint nway missing;
  	class category_root;
  	var actual_price;
  	output out=avg_prices_by_category(drop=_TYPE_ _FREQ_) mean=avg_price;
run;

/* Sort the dataset by descending average price */
proc sort data=avg_prices_by_category;
  	by descending avg_price;
run;

/* Display the top categories with the highest average price */
proc print data=avg_prices_by_category noobs label;
  	title "Top Categories with Higher Average Product Prices";
  	footnote "*This table reveals consumer preferences and probable pricing plans for various product categories";
  	var category_root avg_price;
  	where not missing(category_root);
run;

/* Create a vertical bar chart of the average product prices by category */
proc sgplot data=avg_prices_by_category;
  	vbar category_root / response=avg_price;
  	xaxis label="Category";
  	yaxis label="Average Price";
  	title "Average Product Prices by Category (Bar Chart)";
  	footnote "*Examining Price Trends In Different Product Categories";
run;

/*
[5]. What is the distribution of product ratings among different categories? 
*/

/* Determine the product ratings' frequency distribution */
proc freq data=products_reviews;
  	tables rating / missing;
  	where not missing(rating);
  	title "Product Ratings Frequency Distribution";
  	footnote "*The frequency distribution displays the distribution of product ratings, including any missing values, and shows the frequency and proportion of each rating value among the products under consideration";
run;

/* Create a horizontal box plot of product ratings segmented by category */
proc sgplot data=products_reviews;
  	hbox rating / category=category_root;
  	xaxis label="Product Rating";
  	yaxis display=(nolabel);
  	title "Product Ratings by Category Distribution (Box Plot)";
  	footnote "*Rating Distribution Insights";
run;

ods pdf close;



%web_open_table(WORK.IMPORT);