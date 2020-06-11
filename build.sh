# Convert notebook files to HTML
jupyter nbconvert content/**/*.ipynb --to html --template basic

# Copy images for notebooks to static
cp -r content/notebooks/images/* static/images/

# Build hugo
# hugo