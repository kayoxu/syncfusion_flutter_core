part of charts;

class _CandlePainter extends CustomPainter {
  _CandlePainter(
      {this.chart,
      this.seriesRenderer,
      this.isRepaint,
      this.animationController,
      this.seriesAnimation,
      this.chartElementAnimation,
      ValueNotifier<num> notifier,
      this.painterKey})
      : super(repaint: notifier);

  final SfCartesianChart chart;
  final bool isRepaint;
  final AnimationController animationController;
  final Animation<double> seriesAnimation;
  final Animation<double> chartElementAnimation;
  List<_ChartLocation> currentChartLocations = <_ChartLocation>[];
  CandleSeriesRenderer seriesRenderer;
  final _PainterKey painterKey;

  /// Painter method for candle series
  @override
  void paint(Canvas canvas, Size size) {
    final ChartAxis xAxis = seriesRenderer._xAxis;
    final ChartAxis yAxis = seriesRenderer._yAxis;
    final List<dynamic> dataPoints = seriesRenderer._dataPoints;
    Rect clipRect;
    double animationFactor;
    final CandleSeries<dynamic, dynamic> series = seriesRenderer._series;
    CartesianChartPoint<dynamic> point;
    if (seriesRenderer._visible) {
      canvas.save();
      final int seriesIndex = painterKey.index;
      seriesRenderer.storeSeriesProperties(chart, seriesIndex);
      final Rect axisClipRect = _calculatePlotOffset(
          chart._chartAxis._axisClipRect,
          Offset(xAxis.plotOffset, yAxis.plotOffset));
      canvas.clipRect(axisClipRect);
      animationFactor = seriesAnimation != null ? seriesAnimation.value : 1;
      final _VisibleRange sideBySideInfo =
          _calculateSideBySideInfo(seriesRenderer, chart);
      int segmentIndex = -1;
      for (int pointIndex = 0; pointIndex < dataPoints.length; pointIndex++) {
        point = dataPoints[pointIndex];
        seriesRenderer.calculateRegionData(chart, seriesRenderer,
            painterKey.index, point, pointIndex, sideBySideInfo);
        if (point.isVisible && !point.isGap) {
          seriesRenderer.drawSegment(
              canvas,
              seriesRenderer.addSegment(
                  point, segmentIndex += 1, painterKey.index, animationFactor));
        }
      }
      clipRect = _calculatePlotOffset(
          Rect.fromLTWH(
              chart._chartAxis._axisClipRect.left - series.markerSettings.width,
              chart._chartAxis._axisClipRect.top - series.markerSettings.height,
              chart._chartAxis._axisClipRect.right +
                  series.markerSettings.width,
              chart._chartAxis._axisClipRect.bottom +
                  series.markerSettings.height),
          Offset(xAxis.plotOffset, yAxis.plotOffset));

      canvas.restore();
      if ((series.animationDuration <= 0 ||
              animationFactor >= chart._seriesDurationFactor) &&
          series.dataLabelSettings.isVisible) {
        canvas.clipRect(clipRect);
        seriesRenderer.renderSeriesElements(
            chart, canvas, chartElementAnimation);
      }
      if (seriesRenderer._visible && animationFactor >= 1) {
        chart._chartState
            .setPainterKey(painterKey.index, painterKey.name, true);
      }
    }
  }

  @override
  bool shouldRepaint(_CandlePainter oldDelegate) => isRepaint;
}
