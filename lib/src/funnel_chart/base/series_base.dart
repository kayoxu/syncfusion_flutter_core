part of charts;

class _FunnelSeries {
  _FunnelSeries();

  SfFunnelChart chart;

  _FunnelSeriesBase<dynamic, dynamic> currentSeries;

  List<FunnelSeriesRenderer> visibleSeriesRenderers = <FunnelSeriesRenderer>[];
  SelectionArgs _selectionArgs;

  void _findVisibleSeries() {
    chart._chartSeries.visibleSeriesRenderers[0]._dataPoints =
        <PointInfo<dynamic>>[];

    //Considered the first series, since in triangular series one series will be considered for rendering
    final FunnelSeriesRenderer seriesRenderer =
        chart._chartSeries.visibleSeriesRenderers[0];
    currentSeries = seriesRenderer._series;
    //Setting series type
    seriesRenderer._seriesType = 'funnel';
    final dynamic xValue = currentSeries.xValueMapper;
    final dynamic yValue = currentSeries.yValueMapper;

    for (int pointIndex = 0;
        pointIndex < currentSeries.dataSource.length;
        pointIndex++) {
      if (xValue(pointIndex) != null) {
        seriesRenderer._dataPoints
            .add(PointInfo<dynamic>(xValue(pointIndex), yValue(pointIndex)));
      }
    }
    visibleSeriesRenderers
      ..clear()
      ..add(seriesRenderer);
  }

  void _calculateFunnelEmptyPoints(FunnelSeriesRenderer seriesRenderer) {
    for (int i = 0; i < seriesRenderer._dataPoints.length; i++) {
      if (seriesRenderer._dataPoints[i].y == null)
        seriesRenderer._series.calculateEmptyPointValue(
            i, seriesRenderer._dataPoints[i], seriesRenderer);
    }
  }

  void _processDataPoints(FunnelSeriesRenderer seriesRenderer) {
    currentSeries = seriesRenderer._series;
    _calculateFunnelEmptyPoints(seriesRenderer);
    _calculateVisiblePoints(seriesRenderer);
    _setPointStyle(seriesRenderer);
    _findSumOfPoints(seriesRenderer);
  }

  void _calculateVisiblePoints(FunnelSeriesRenderer seriesRenderer) {
    final List<PointInfo<dynamic>> points = seriesRenderer._dataPoints;
    seriesRenderer._renderPoints = <PointInfo<dynamic>>[];
    for (int i = 0; i < points.length; i++) {
      if (points[i].isVisible) {
        seriesRenderer._renderPoints.add(points[i]);
      }
    }
  }

  void _setPointStyle(FunnelSeriesRenderer seriesRenderer) {
    currentSeries = seriesRenderer._series;
    final List<Color> palette = chart.palette;
    final dynamic pointColor = currentSeries.pointColorMapper;
    final EmptyPointSettings empty = currentSeries.emptyPointSettings;
    final dynamic textMapping = currentSeries.textFieldMapper;
    final List<PointInfo<dynamic>> points = seriesRenderer._renderPoints;
    for (int i = 0; i < points.length; i++) {
      PointInfo<dynamic> currentPoint;
      currentPoint = points[i];
      currentPoint.fill = currentPoint.isEmpty && empty.color != null
          ? empty.color
          : pointColor(i) ?? palette[i % palette.length];
      currentPoint.color = currentPoint.fill;
      currentPoint.borderColor =
          currentPoint.isEmpty && empty.borderColor != null
              ? empty.borderColor
              : currentSeries.borderColor;
      currentPoint.borderWidth =
          currentPoint.isEmpty && empty.borderWidth != null
              ? empty.borderWidth
              : currentSeries.borderWidth;
      currentPoint.borderColor = currentPoint.borderWidth == 0
          ? Colors.transparent
          : currentPoint.borderColor;

      currentPoint.text = currentPoint.text == null
          ? textMapping != null
              ? textMapping(i) ?? currentPoint.y.toString()
              : currentPoint.y.toString()
          : currentPoint.text;

      if (chart.legend.legendItemBuilder != null) {
        final List<_MeasureWidgetContext> legendToggles =
            chart._chartState.legendToggleTemplateStates;
        if (legendToggles.isNotEmpty) {
          for (int j = 0; j < legendToggles.length; j++) {
            final _MeasureWidgetContext item = legendToggles[j];
            if (i == item.pointIndex) {
              currentPoint.isVisible = false;
              break;
            }
          }
        }
      } else {
        if (chart._chartState.legendToggleStates.isNotEmpty) {
          for (int j = 0;
              j < chart._chartState.legendToggleStates.length;
              j++) {
            final _LegendRenderContext legendRenderContext =
                chart._chartState.legendToggleStates[j];
            if (i == legendRenderContext.seriesIndex) {
              currentPoint.isVisible = false;
              break;
            }
          }
        }
      }
    }
  }

  void _findSumOfPoints(FunnelSeriesRenderer seriesRenderer) {
    seriesRenderer._sumOfPoints = 0;
    for (PointInfo<dynamic> point in seriesRenderer._renderPoints) {
      if (point.isVisible) {
        seriesRenderer._sumOfPoints += point.y.abs();
      }
    }
  }

  void _initializeSeriesProperties(FunnelSeriesRenderer seriesRenderer) {
    final Rect chartAreaRect = chart._chartState.chartAreaRect;
    final FunnelSeries<dynamic, dynamic> series = seriesRenderer._series;
    final bool reverse = seriesRenderer._seriesType == 'pyramid' ? true : false;
    seriesRenderer._triangleSize = Size(
        _percentToValue(series.width, chartAreaRect.width).toDouble(),
        _percentToValue(series.height, chartAreaRect.height).toDouble());
    seriesRenderer._neckSize = Size(
        _percentToValue(series.neckWidth, chartAreaRect.width).toDouble(),
        _percentToValue(series.neckHeight, chartAreaRect.height).toDouble());
    seriesRenderer._explodeDistance =
        _percentToValue(series.explodeOffset, chartAreaRect.width);
    _initializeSizeRatio(seriesRenderer, reverse);
  }

  void _initializeSizeRatio(FunnelSeriesRenderer seriesRenderer,
      [bool reverse]) {
    final List<PointInfo<dynamic>> points = seriesRenderer._renderPoints;
    double y;
    final double gapRatio = min(max(seriesRenderer._series.gapRatio, 0), 1);
    final double coEff =
        1 / (seriesRenderer._sumOfPoints * (1 + gapRatio / (1 - gapRatio)));
    final double spacing = gapRatio / (points.length - 1);
    y = 0;
    num index;
    num height;
    for (num i = points.length - 1; i >= 0; i--) {
      index = reverse ? points.length - 1 - i : i;
      if (points[index].isVisible) {
        height = coEff * points[index].y;
        points[index].yRatio = y;
        points[index].heightRatio = height;
        y += height + spacing;
      }
    }
  }

  void _calculatePathSegment(String seriesType, PointInfo<dynamic> point) {
    final List<Offset> pathRegion = point.pathRegion;
    final num bottom =
        seriesType == 'funnel' ? pathRegion.length - 2 : pathRegion.length - 1;
    final num x = (pathRegion[0].dx + pathRegion[bottom].dx) / 2;
    final num right = (pathRegion[1].dx + pathRegion[bottom - 1].dx) / 2;
    point.region = Rect.fromLTWH(x, pathRegion[0].dy, right - x,
        pathRegion[bottom].dy - pathRegion[0].dy);
    point.symbolLocation = Offset(point.region.left + point.region.width / 2,
        point.region.top + point.region.height / 2);
  }

  void _pointExplode(num pointIndex) {
    bool existExplodedRegion = false;
    final FunnelSeriesRenderer seriesRenderer =
        chart._chartSeries.visibleSeriesRenderers[0];
    final _SfFunnelChartState chartState = chart._chartState;
    final PointInfo<dynamic> point = seriesRenderer._renderPoints[pointIndex];
    if (seriesRenderer._series.explode) {
      if (chartState.explodedPoints.isNotEmpty) {
        existExplodedRegion = true;
        final int previousIndex = chartState.explodedPoints[0];
        seriesRenderer._renderPoints[previousIndex].explodeDistance = 0;
        point.explodeDistance =
            previousIndex == pointIndex ? 0 : seriesRenderer._explodeDistance;
        chartState.explodedPoints[0] = pointIndex;
        if (previousIndex == pointIndex) {
          chartState.explodedPoints = <int>[];
        }
        chartState.seriesRepaintNotifier.value++;
      }
      if (!existExplodedRegion) {
        point.explodeDistance = seriesRenderer._explodeDistance;
        chartState.explodedPoints.add(pointIndex);
        chartState.seriesRepaintNotifier.value++;
      }
      _calculateFunnelPathRegion(pointIndex, seriesRenderer);
    }
  }

  void _calculateFunnelPathRegion(
      num pointIndex, FunnelSeriesRenderer seriesRenderer) {
    num lineWidth,
        topRadius,
        bottomRadius,
        endTop,
        endBottom,
        minRadius,
        endMin,
        bottomY,
        top,
        bottom;
    final Size area = seriesRenderer._triangleSize;
    const num offset = 0;
    final dynamic currentPoint = seriesRenderer._renderPoints[pointIndex];
    currentPoint.pathRegion = <Offset>[];
    final Rect rect = chart._chartState.chartContainerRect;
    final num extraSpace = (currentPoint.explodeDistance != null
            ? currentPoint.explodeDistance
            : _isNeedExplode(pointIndex, currentSeries, chart)
                ? seriesRenderer._explodeDistance
                : 0) +
        (rect.width - seriesRenderer._triangleSize.width) / 2;
    final num emptySpaceAtLeft = extraSpace + rect.left;
    final num seriesTop = rect.top + (rect.height - area.height) / 2;
    top = currentPoint.yRatio * area.height;
    bottom = top + currentPoint.heightRatio * area.height;
    final Size neckSize = seriesRenderer._neckSize;
    lineWidth = neckSize.width +
        (area.width - neckSize.width) *
            ((area.height - neckSize.height - top) /
                (area.height - neckSize.height));
    topRadius = (area.width / 2) - lineWidth / 2;
    endTop = topRadius + lineWidth;
    if (bottom > area.height - neckSize.height ||
        area.height == neckSize.height) {
      lineWidth = neckSize.width;
    } else {
      lineWidth = neckSize.width +
          (area.width - neckSize.width) *
              ((area.height - neckSize.height - bottom) /
                  (area.height - neckSize.height));
    }
    bottomRadius = (area.width / 2) - (lineWidth / 2);
    endBottom = bottomRadius + lineWidth;
    if (top >= area.height - neckSize.height) {
      topRadius =
          bottomRadius = minRadius = (area.width / 2) - neckSize.width / 2;
      endTop = endBottom = endMin = (area.width / 2) + neckSize.width / 2;
    } else if (bottom > (area.height - neckSize.height)) {
      minRadius = bottomRadius = (area.width / 2) - lineWidth / 2;
      endMin = endBottom = minRadius + lineWidth;
      bottomY = area.height - neckSize.height;
    }
    top += seriesTop;
    bottom += seriesTop;
    bottomY = (bottomY != null) ? (bottomY + seriesTop) : null;
    num line1X,
        line1Y,
        line2X,
        line2Y,
        line3X,
        line3Y,
        line4X,
        line4Y,
        line5X,
        line5Y,
        line6X,
        line6Y;
    line1X = emptySpaceAtLeft + offset + topRadius;
    line1Y = top;
    line2X = emptySpaceAtLeft + offset + endTop;
    line2Y = top;
    line4X = emptySpaceAtLeft + offset + endBottom;
    line4Y = bottom;
    line5X = emptySpaceAtLeft + offset + bottomRadius;
    line5Y = bottom;
    line3X = emptySpaceAtLeft + offset + endBottom;
    line3Y = bottom;
    line6X = emptySpaceAtLeft + offset + bottomRadius;
    line6Y = bottom;
    if (bottomY != null) {
      line3X = emptySpaceAtLeft + offset + endMin;
      line3Y = bottomY;
      line6X =
          emptySpaceAtLeft + offset + ((minRadius != null) ? minRadius : 0);
      line6Y = bottomY;
    }
    currentPoint.pathRegion.add(Offset(line1X, line1Y));
    currentPoint.pathRegion.add(Offset(line2X, line2Y));
    currentPoint.pathRegion.add(Offset(line3X, line3Y));
    currentPoint.pathRegion.add(Offset(line4X, line4Y));
    currentPoint.pathRegion.add(Offset(line5X, line5Y));
    currentPoint.pathRegion.add(Offset(line6X, line6Y));
    _calculatePathSegment(seriesRenderer._seriesType, currentPoint);
  }

  void _calculateFunnelSegments(
      Canvas canvas, num pointIndex, FunnelSeriesRenderer seriesRenderer) {
    _calculateFunnelPathRegion(pointIndex, seriesRenderer);
    final dynamic currentPoint = seriesRenderer._renderPoints[pointIndex];
    final Path path = Path();
    path.moveTo(currentPoint.pathRegion[0].dx, currentPoint.pathRegion[0].dy);
    path.lineTo(currentPoint.pathRegion[1].dx, currentPoint.pathRegion[1].dy);
    path.lineTo(currentPoint.pathRegion[2].dx, currentPoint.pathRegion[2].dy);
    path.lineTo(currentPoint.pathRegion[3].dx, currentPoint.pathRegion[3].dy);
    path.lineTo(currentPoint.pathRegion[4].dx, currentPoint.pathRegion[4].dy);
    path.lineTo(currentPoint.pathRegion[5].dx, currentPoint.pathRegion[5].dy);
    path.close();
    if (pointIndex == seriesRenderer._renderPoints.length - 1) {
      seriesRenderer._maximumDataLabelRegion = path.getBounds();
    }
    _segmentPaint(canvas, path, pointIndex, seriesRenderer);
  }

  void _segmentPaint(Canvas canvas, Path path, num pointIndex,
      FunnelSeriesRenderer seriesRenderer) {
    final dynamic point = seriesRenderer._renderPoints[pointIndex];
    final _StyleOptions style =
        _getPointStyle(pointIndex, seriesRenderer, chart, point);

    final Color fillColor =
        style != null && style.fill != null ? style.fill : point.fill;

    final Color strokeColor = style != null && style.strokeColor != null
        ? style.strokeColor
        : point.borderColor;

    final double strokeWidth = style != null && style.strokeWidth != null
        ? style.strokeWidth
        : point.borderWidth;

    final double opacity = style != null && style.opacity != null
        ? style.opacity
        : currentSeries.opacity;

    _drawPath(
        canvas,
        _StyleOptions(
            fillColor,
            chart._chartState.animateCompleted ? strokeWidth : 0,
            strokeColor,
            opacity),
        path);
  }

  void _seriesPointSelection(num pointIndex, ActivationMode mode) {
    bool isPointAlreadySelected = false;
    final dynamic seriesRenderer = chart._chartSeries.visibleSeriesRenderers[0];
    final List<int> selectionData = chart._chartState.selectionData;
    if (seriesRenderer._series.selectionSettings.enable &&
        mode == chart.selectionGesture) {
      if (selectionData.isNotEmpty) {
        for (int i = 0; i < selectionData.length; i++) {
          final int selectionIndex = selectionData[i];
          if (!chart.enableMultiSelection) {
            isPointAlreadySelected =
                selectionData.length == 1 && pointIndex == selectionIndex;
            selectionData.removeAt(i);
            chart._chartState.seriesRepaintNotifier.value++;
          } else if (pointIndex == selectionIndex) {
            selectionData.removeAt(i);
            isPointAlreadySelected = true;
            chart._chartState.seriesRepaintNotifier.value++;
            break;
          }
        }
      }
      if (!isPointAlreadySelected) {
        selectionData.add(pointIndex);
        chart._chartState.seriesRepaintNotifier.value++;
      }
    }
  }

  _StyleOptions _getPointStyle(
      int currentPointIndex,
      FunnelSeriesRenderer seriesRenderer,
      SfFunnelChart chart,
      PointInfo<dynamic> point) {
    _StyleOptions pointStyle;
    final SelectionSettings selection =
        seriesRenderer._series.selectionSettings;
    const num seriesIndex = 0;
    final List<int> selectionData = chart._chartState.selectionData;
    if (selection.enable) {
      if (selectionData.isNotEmpty) {
        if (chart.onSelectionChanged != null) {
          chart.onSelectionChanged(_getSelectionEventArgs(
              seriesRenderer, seriesIndex, currentPointIndex));
        }
        for (int i = 0; i < selectionData.length; i++) {
          final int selectionIndex = selectionData[i];
          if (currentPointIndex == selectionIndex) {
            pointStyle = _StyleOptions(
                _selectionArgs != null
                    ? _selectionArgs.selectedColor
                    : selection.selectedColor,
                _selectionArgs != null
                    ? _selectionArgs.selectedBorderWidth
                    : selection.selectedBorderWidth,
                _selectionArgs != null
                    ? _selectionArgs.selectedBorderColor
                    : selection.selectedBorderColor,
                selection.selectedOpacity);
            break;
          } else if (i == selectionData.length - 1) {
            pointStyle = _StyleOptions(
                _selectionArgs != null
                    ? _selectionArgs.unselectedColor
                    : selection.unselectedColor,
                _selectionArgs != null
                    ? _selectionArgs.unselectedBorderWidth
                    : selection.unselectedBorderWidth,
                _selectionArgs != null
                    ? _selectionArgs.unselectedBorderColor
                    : selection.unselectedBorderColor,
                selection.unselectedOpacity);
          }
        }
      }
    }
    return pointStyle;
  }

  SelectionArgs _getSelectionEventArgs(
      dynamic seriesRenderer, num seriesIndex, num pointIndex) {
    final FunnelSeries<dynamic, dynamic> series = seriesRenderer._series;
    if (series != null) {
      _selectionArgs =
          SelectionArgs(seriesRenderer, seriesIndex, pointIndex, pointIndex);
      _selectionArgs.selectedBorderColor =
          series.selectionSettings.selectedBorderColor;
      _selectionArgs.selectedBorderWidth =
          series.selectionSettings.selectedBorderWidth;
      _selectionArgs.selectedColor = series.selectionSettings.selectedColor;
      _selectionArgs.unselectedBorderColor =
          series.selectionSettings.unselectedBorderColor;
      _selectionArgs.unselectedBorderWidth =
          series.selectionSettings.unselectedBorderWidth;
      _selectionArgs.unselectedColor = series.selectionSettings.unselectedColor;
    }
    return _selectionArgs;
  }
}
