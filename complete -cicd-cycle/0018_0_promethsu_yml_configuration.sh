scrape_configs:
  - job_name: 'postgres_exporter'
    static_configs:
      - targets: ['rough_work-postgres_exporter-1:9187']


If you are getting ssl related issues update the exporter configuration:



