## ---- results='hide', error=FALSE, message=FALSE, warning=FALSE----------------------------------------------


library(tidyverse) # ggplot2, dplyr, tidyr, readr, purrr, tibble
library(magrittr) # pipes
library(lintr) # code linting
library(sf) # spatial data handling
library(here)
library(hrbrthemes)

# Create legend df and attach bivariant color code to df for plotting
# Function

calculate_quantiles <- function(var){
    quantiles_var <- var %>%
        quantile(probs = seq(0, 1, length.out = 4))
    return(quantiles_var)
}

calculate_natural_breaks <- function(var){
    n=3
    var_df <- data.frame(var)

    jenks_var <- c(0,natural_breaks(n,var_df['var']))
    
    if(jenks_var[3] == max(var_df$var,na.rm = TRUE)){
        n=4
        jenks_var <- c(0,natural_breaks(n,var_df['var']))
    }else{
        jenks_var <- c(jenks_var,max(var_df$var,na.rm = TRUE))
    }
    
    return(jenks_var)
}

generate_bivariant_color_df <- function(var1,var2){
    ## ----message=FALSE, warning=FALSE----------------------------------------------------------------------------
    
    # create 3 buckets for customers affected by severe and extreme power disruptions
    breaks_var1 <- calculate_natural_breaks(var1)
    breaks_var2 <- calculate_natural_breaks(var2)
 
    # create color scale that encodes two variables
    # red for gini and blue for mean income
    # the special notation with gather is due to readibility reasons
    bivariant_color_scale <- tibble(
        "3 - 3" = "#3F2949", # high customers with power disruption, high % DME
        "2 - 3" = "#435786",
        "1 - 3" = "#4885C1", # low customers with power disruption, high % DME
        "3 - 2" = "#77324C",
        "2 - 2" = "#806A8A", # medium customers with power disruption, medium % DME
        "1 - 2" = "#89A1C8",
        "3 - 1" = "#AE3A4E", # high customers with power disruption, low % DME
        "2 - 1" = "#BC7C8F",
        "1 - 1" = "#CABED0" # low customers with power disruption, low % DME
    ) %>%
        gather("group", "fill")
    
    return(bivariant_color_scale)
}



attach_color_df <- function(df,bivariant_color_scale,
                            var1,var2){
    
    breaks_var1 <- calculate_natural_breaks(var1)
    breaks_var2 <- calculate_natural_breaks(var2)
    # Add color code to df
    df %<>%
        mutate(
            var1_breaks = cut(
                var1,
                breaks = breaks_var1,
                include.lowest = TRUE
            ),
            var2_breaks = cut(
                var2,
                breaks = breaks_var2,
                include.lowest = TRUE
            ),
            # by pasting the factors together as numbers we match the groups defined
            # in the tibble bivariant_color_scale
            group = paste(
                as.numeric(var1_breaks), "-",
                as.numeric(var2_breaks)
            )
        ) %>%
        # we now join the actual hex values per "group"
        # so each municipality knows its hex value based on the his gini and avg
        # income value
        left_join(bivariant_color_scale, by = "group")
    
    return(df)
    
}


generate_bivarant_legend_df <- function(bivariant_color_scale,
                                        var1,var2){
    
    breaks_var1 <- calculate_natural_breaks(var1)
    breaks_var2 <- calculate_natural_breaks(var2)
    
    ## ----message=FALSE, warning=FALSE----------------------------------------------------------------------------
    # separate the groups
    bivariant_color_scale %<>%
        separate(group, into = c("var1", "var2"), sep = " - ") %>%
        mutate(var1 = as.integer(var1),
               var2 = as.integer(var2))
    
    
    # print(bivariant_color_scale)
    
    var1_label <- format((plyr::round_any(breaks_var1,1000))/1000,
                         big.mark = ",")
    var1_label <- c(
        paste0("High: >",var1_label[3]),
        paste0("Moderate: ",var1_label[2],"-",var1_label[3]),
        paste0("Low: <",var1_label[2]),
        "","","","","","")
    
    
    var2_label <- format(breaks_var2,
                         big.mark = ",")
    var2_label <- c(paste0("High: >",var2_label[3]),"","",
                    paste0("Moderate: ",var2_label[2],"-",var2_label[3]),"","",
                    paste0("Low: <",var2_label[2]),"",""
                    )
    

    
    bivariant_color_scale %<>%
        mutate(
            var1_label = var1_label,
            var2_label = var2_label)
    
    return(bivariant_color_scale)
    
}


bivariant_legend_plot <- function(bivariant_legend_df){
    
    legend_plot <- ggplot() +
        geom_tile(
            data = bivariant_legend_df,
            mapping = aes(
                x = var1,
                y = var2,
                fill = fill)
        ) +
        scale_fill_identity() +
        labs(x = "Customers affected (K)",
             y = "Power disruptions")+
        # theme_ipsum() +
        theme_bw()+
        # make font big enough
        theme(
            axis.text.x = element_text(size = 14),
            axis.text.y = element_text(size = 14),
            axis.title.x = element_text(size = 14),
            axis.title.y = element_text(size= 14),
            plot.margin = unit(c(0,0,0,0), "cm")
            # axis.line = element_line(colour = "black", 
            #                     size = 1, linetype = "solid")
        ) +
        scale_x_continuous(breaks = bivariant_legend_df$var1,
                           labels = bivariant_legend_df$var1_label,
                           guide = guide_axis(angle=45))+
        scale_y_continuous(breaks = bivariant_legend_df$var2,
                           labels = bivariant_legend_df$var2_label)+
        # quadratic tiles
        coord_fixed()
    
    return(legend_plot)
    
    
}

bivariant_map_plot <- function(df,title){
    ggplot(
        # use the same dataset as before
        data = df
    ) +
        # color municipalities according to their gini / income combination
        geom_sf(
            aes(
                fill = fill
            ),
            # use thin white stroke for municipalities
            color = "white",
            size = 0.1
        ) +
        # geom_text(aes(x=x_map,y=y_map,label = label),
        #           # nudge_x = .6,nudge_y = .6,
        #           # vjust =-0.8,
        #           fontface = "bold",
        #           size = 3,color="white")+
        # as the sf object municipality_prod_geo has a column with name "fill" that
        # contains the literal color as hex code for each municipality, we can use
        # scale_fill_identity here
        scale_fill_identity() +
        # use thicker white stroke for cantons
        geom_sf(
            data = df,
            fill = "transparent",
            color = "white",
            size = 0.3
        ) +
        # add titles
        labs(x = NULL,
             y = NULL,
             title = title) +
        # add the theme
        theme_map()
}



